#!/bin/bash
# Approve a candidate currently in 'awaiting_review' → run the tier-aware
# publish flow + channel adapters. Invoked by the dashboard's approve button,
# or manually from the command line.
#
# Usage:
#   bash tools/curator/approve.sh <id>
#
# Reads:
#   - pending_drafts/<id>.astro          the staged Astro page
#   - pending_drafts/<id>.judges.json    captured judge scores (for provenance)
#   - the manifest for <id> in either lab
#
# On success:
#   - publish_draft runs (tier 1: PR, tier 2: PR+auto-merge, tier 3: branch+tag)
#   - manifest curator_state → 'published'
#   - channel adapters fire if 'hackernews' or 'linkedin' in channels[]
#   - pending_drafts files cleaned up

set -euo pipefail

CURATOR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WEBSITE_ROOT="$( cd "$CURATOR_DIR/../.." && pwd )"
export CURATOR_DIR

. "$CURATOR_DIR/lib/log.sh"
. "$CURATOR_DIR/lib/publish.sh"
. "$CURATOR_DIR/lib/channel_hackernews.sh"
. "$CURATOR_DIR/lib/channel_linkedin.sh"

TARGET_ID="${1:-}"
if [ -z "$TARGET_ID" ]; then
    echo "usage: $0 <id>" >&2
    exit 2
fi

# Locate the candidate file across both labs.
CANDIDATE=""
for dir in "$HOME/Desktop/Fun/lab/publish_candidates" "$HOME/Desktop/AGI/data/publish_candidates"; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.json; do
        [ -f "$f" ] || continue
        FID=$(F="$f" python3 -c "import os, json; print(json.load(open(os.environ['F'])).get('id',''))" 2>/dev/null)
        if [ "$FID" = "$TARGET_ID" ]; then
            CANDIDATE="$f"
            break 2
        fi
    done
done

if [ -z "$CANDIDATE" ]; then
    log_error "approve: no candidate with id=$TARGET_ID"
    exit 1
fi

STATE=$(F="$CANDIDATE" python3 -c "import os, json; print(json.load(open(os.environ['F'])).get('curator_state',''))")
if [ "$STATE" != "awaiting_review" ]; then
    log_error "approve: candidate state is '$STATE', not 'awaiting_review'"
    exit 1
fi

PENDING_DRAFT="$CURATOR_DIR/pending_drafts/${TARGET_ID}.astro"
PENDING_JUDGES="$CURATOR_DIR/pending_drafts/${TARGET_ID}.judges.json"
if [ ! -f "$PENDING_DRAFT" ]; then
    log_error "approve: pending draft missing: $PENDING_DRAFT"
    exit 1
fi
JUDGES_JSON="{}"
[ -f "$PENDING_JUDGES" ] && JUDGES_JSON=$(cat "$PENDING_JUDGES")

log_section "approve: $TARGET_ID"

if ! publish_draft "$PENDING_DRAFT" "$CANDIDATE" "$JUDGES_JSON"; then
    log_error "approve: publish_draft failed for $TARGET_ID"
    exit 1
fi

# Mark published + clean up review-state fields.
CANDIDATE="$CANDIDATE" python3 <<'PYEOF'
import os, json, datetime
p = os.environ['CANDIDATE']
d = json.load(open(p))
d['curator_state'] = 'published'
d['published_at'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
d.pop('pending_draft', None)
d.pop('awaiting_review_at', None)
open(p, 'w').write(json.dumps(d, indent=2))
PYEOF
log_info "approve: $TARGET_ID → published"

# Channel adapters: reuse the pre-generated drafts from review staging when
# present (no need to re-call Claude for the LinkedIn teaser the operator
# already saw). Only regenerate if the pending file is missing — e.g.,
# because the operator approved via legacy path or the staging step failed.
CHANNELS=$(CANDIDATE="$CANDIDATE" python3 -c "import os, json; print(' '.join(json.load(open(os.environ['CANDIDATE'])).get('channels', ['website'])))" 2>/dev/null || echo "website")
log_section "channel adapters"
for ch in $CHANNELS; do
    case "$ch" in
        website) ;;
        hackernews|linkedin)
            PENDING_CH="$CURATOR_DIR/pending_drafts/${TARGET_ID}.${ch}.txt"
            FINAL_DIR="$CURATOR_DIR/channel_drafts/${ch}"
            FINAL_PATH="${FINAL_DIR}/${TARGET_ID}.txt"
            mkdir -p "$FINAL_DIR"
            if [ -f "$PENDING_CH" ]; then
                mv "$PENDING_CH" "$FINAL_PATH"
                log_info "approve: ${ch} draft moved from review staging → $FINAL_PATH"
            else
                log_warn "approve: no pre-generated ${ch} draft; regenerating now"
                if [ "$ch" = "hackernews" ]; then
                    channel_hackernews "$CANDIDATE" || log_warn "HN adapter failed (non-blocking)"
                else
                    channel_linkedin "$CANDIDATE" || log_warn "LinkedIn adapter failed (non-blocking)"
                fi
            fi
            ;;
        *)
            log_warn "unknown channel: $ch"
            ;;
    esac
done

rm -f "$PENDING_DRAFT" "$PENDING_JUDGES" "${PENDING_DRAFT}.prev"
log_info "approve: $TARGET_ID complete"
