#!/bin/bash
# Curator orchestrator — daily entrypoint.
# Reads new manifest entries from each lab's publish_candidates/ dir,
# runs each through the full pipeline (classify → draft → judge →
# validate → provenance → publish-by-tier), and logs the result.
#
# Usage:
#   bash tools/curator/run.sh           # full run
#   CURATOR_DEBUG=1 bash tools/curator/run.sh   # extra logging
#   bash tools/curator/run.sh --skip-ram-check  # bypass RAM precondition
#   DRY_RUN=1 bash tools/curator/run.sh         # log what would happen, don't push

set -uo pipefail

CURATOR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WEBSITE_ROOT="$( cd "$CURATOR_DIR/../.." && pwd )"
export CURATOR_DIR

. "$CURATOR_DIR/lib/log.sh"
. "$CURATOR_DIR/lib/ram_check.sh"
. "$CURATOR_DIR/lib/forbidden_check.sh"
. "$CURATOR_DIR/lib/classify.sh"
. "$CURATOR_DIR/lib/draft.sh"
. "$CURATOR_DIR/lib/judge.sh"
. "$CURATOR_DIR/lib/validate.sh"
. "$CURATOR_DIR/lib/provenance.sh"
. "$CURATOR_DIR/lib/publish.sh"

SKIP_RAM_CHECK=0
for arg in "$@"; do
    case "$arg" in
        --skip-ram-check) SKIP_RAM_CHECK=1 ;;
        *) log_warn "unknown arg: $arg" ;;
    esac
done

on_exit() {
    local code=$?
    if [ "$code" -ne 0 ]; then
        log_error "curator run FAILED with exit code $code"
    else
        log_section "curator run end (exit 0)"
    fi
    exit "$code"
}
trap on_exit EXIT

# ── Stage 0: RAM precondition ───────────────────────────────────────────
log_section "stage 0: RAM precondition"
if [ "$SKIP_RAM_CHECK" -eq 0 ]; then
    if ! ram_check 12; then
        log_warn "RAM tight; deferring this run."
        exit 0
    fi
else
    log_info "ram_check skipped (--skip-ram-check)"
fi

# ── Stage 1: scan manifests ─────────────────────────────────────────────
log_section "stage 1: scan manifests"

HIVE_MANIFEST_DIR="$HOME/Desktop/Fun/lab/publish_candidates"
AGI_MANIFEST_DIR="$HOME/Desktop/AGI/data/publish_candidates"

# Find all candidates with curator_state == "pending"
CANDIDATES=()
for dir in "$HIVE_MANIFEST_DIR" "$AGI_MANIFEST_DIR"; do
    if [ -d "$dir" ]; then
        for f in "$dir"/*.json; do
            [ -f "$f" ] || continue
            STATE=$(python3 -c "import json; print(json.load(open('$f')).get('curator_state', 'pending'))" 2>/dev/null)
            if [ "$STATE" = "pending" ]; then
                CANDIDATES+=("$f")
            fi
        done
    fi
done

log_info "found ${#CANDIDATES[@]} pending candidate(s)"

if [ "${#CANDIDATES[@]}" -eq 0 ]; then
    log_info "no new candidates → exit clean"
    exit 0
fi

# ── Per-candidate pipeline ──────────────────────────────────────────────
for candidate in "${CANDIDATES[@]}"; do
    log_section "candidate: $(basename "$candidate")"
    START_EPOCH=$(date +%s)

    # Mark as processing (in-place edit; reverts on hold/fail)
    python3 -c "
import json
d = json.load(open('$candidate'))
d['curator_state'] = 'processing'
open('$candidate','w').write(json.dumps(d, indent=2))
"

    # Stage 2: classify risk
    log_section "stage 2: classify risk"
    TIER=$(classify_candidate "$candidate" 2>&1 | tail -1)
    if [ -z "$TIER" ] || ! [[ "$TIER" =~ ^[123]$ ]]; then
        log_warn "classify returned non-numeric ('$TIER'), defaulting to Tier 1"
        TIER=1
    fi
    # Update manifest with tier
    python3 -c "
import json
d = json.load(open('$candidate'))
d['risk_tier'] = $TIER
open('$candidate','w').write(json.dumps(d, indent=2))
"
    log_info "candidate tier: $TIER"

    # Stage 3: draft
    log_section "stage 3: draft via claude --print"
    DRAFT_PATH=$(mktemp /tmp/curator_draft.XXXXXX.astro)
    if ! draft_candidate "$candidate" > "$DRAFT_PATH"; then
        log_error "drafting failed; marking candidate held"
        python3 -c "
import json
d = json.load(open('$candidate'))
d['curator_state'] = 'held'
d['held_reason'] = 'drafting failed'
open('$candidate','w').write(json.dumps(d, indent=2))
"
        rm -f "$DRAFT_PATH"
        continue
    fi

    # Stage 4: judges
    log_section "stage 4: judges"
    JUDGES_OUT=$(mktemp /tmp/curator_judges.XXXXXX.json)
    if ! judge_draft "$DRAFT_PATH" "$candidate" > "$JUDGES_OUT"; then
        HELD_REASON=$(python3 -c "import json; print(json.load(open('$JUDGES_OUT')).get('held_reason', 'judges held'))")
        log_warn "judges held the draft: $HELD_REASON"
        python3 -c "
import json
d = json.load(open('$candidate'))
d['curator_state'] = 'held'
d['held_reason'] = '''$HELD_REASON'''
d['scores'] = json.load(open('$JUDGES_OUT'))
open('$candidate','w').write(json.dumps(d, indent=2))
"
        rm -f "$DRAFT_PATH" "$JUDGES_OUT"
        continue
    fi
    log_info "judges: PASS"

    # Stage 5: provenance
    log_section "stage 5: provenance"
    NOW_EPOCH=$(date +%s)
    COST_SECONDS=$((NOW_EPOCH - START_EPOCH))
    JUDGES_JSON=$(cat "$JUDGES_OUT")
    inject_provenance "$DRAFT_PATH" "$candidate" "$JUDGES_JSON" "$COST_SECONDS"

    # Stage 6: validate
    log_section "stage 6: validate"
    if ! validate_draft "$DRAFT_PATH" "$candidate"; then
        log_warn "validators held the draft"
        python3 -c "
import json
d = json.load(open('$candidate'))
d['curator_state'] = 'held'
d['held_reason'] = 'validators failed'
open('$candidate','w').write(json.dumps(d, indent=2))
"
        rm -f "$DRAFT_PATH" "$JUDGES_OUT"
        continue
    fi

    # Stage 7: publish (tier-aware)
    log_section "stage 7: publish (tier $TIER)"
    if ! publish_draft "$DRAFT_PATH" "$candidate" "$JUDGES_JSON"; then
        log_error "publish failed for $candidate"
        python3 -c "
import json
d = json.load(open('$candidate'))
d['curator_state'] = 'held'
d['held_reason'] = 'publish flow failed'
open('$candidate','w').write(json.dumps(d, indent=2))
"
        rm -f "$DRAFT_PATH" "$JUDGES_OUT"
        continue
    fi

    # Mark published
    python3 -c "
import json, datetime
d = json.load(open('$candidate'))
d['curator_state'] = 'published'
d['published_at'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
open('$candidate','w').write(json.dumps(d, indent=2))
"
    log_info "candidate $(basename "$candidate") → published (tier $TIER, ${COST_SECONDS}s)"

    rm -f "$DRAFT_PATH" "$JUDGES_OUT"
done

log_info "all candidates processed"
