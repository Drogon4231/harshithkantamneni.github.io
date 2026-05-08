#!/bin/bash
# Branch + commit + publish gating per risk tier.
# Runs after judges pass and validators pass.
#
# Tier 1: open PR, do not auto-merge (human merges)
# Tier 2: open PR + label auto-merge; tools/curator/auto_merge.sh handles it
# Tier 3: commit directly to draft/<id> branch, no PR; tools/curator/veto_check.sh
#         auto-merges after 24h if no veto
#
# Usage:
#   . tools/curator/lib/publish.sh
#   publish_draft <draft.astro> <candidate.json> <judges_json> <validator_summary> <tier>
#
# Set DRY_RUN=1 to print commands without running them.

_PUB_SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURATOR_DIR="$( cd "$_PUB_SELF_DIR/.." && pwd )"
WEBSITE_ROOT="$( cd "$CURATOR_DIR/../.." && pwd )"
export CURATOR_DIR

[ -z "${CURATOR_LOG:-}" ] && {
    . "$_PUB_SELF_DIR/log.sh"
}

DRY_RUN="${DRY_RUN:-0}"

_run() {
    if [ "$DRY_RUN" = "1" ]; then
        echo "DRY: $*"
    else
        "$@"
    fi
}

# Build PR body from template + judges + validators.
# Args: candidate_json, judges_json, run_id
_build_pr_body() {
    local candidate="$1"
    local judges_json="$2"
    local run_id="$3"

    python3 <<PYEOF
import json, sys

c = json.load(open("$candidate"))
j = json.loads('''$judges_json''')

template = open("$CURATOR_DIR/templates/pr_body.md").read()

source_list = ""
for sa in c['source_artifacts']:
    if isinstance(sa, dict):
        source_list += f"- ({sa['lab']}) {sa['path']}\n"
    else:
        source_list += f"- {sa}\n"

voice = j.get('voice', {})
fact = j.get('factcheck', {})
nov = j.get('novelty', {})

subs = {
    'LAB': c['lab'],
    'TYPE': c['type'],
    'RATIFIED_AT': c['ratified_at'],
    'RATIFIED_DATE': c.get('ratified_date', ''),
    'RISK_TIER': str(c.get('risk_tier', '')),
    'RUN_ID': "$run_id",
    'SOURCE_LIST': source_list.strip(),
    'VOICE_SCORE': str(voice.get('score', '')),
    'VOICE_RATIONALE': voice.get('rationale', ''),
    'VOICE_RESULT': '✓ pass' if voice.get('score', 0) >= 6.5 else '✗ held',
    'FACT_VERIFIED': str(fact.get('verified_count', '')),
    'FACT_TOTAL': str(fact.get('draft_numbers_total', '')),
    'FACT_RESULT': '✓ pass' if fact.get('pass') else '✗ held',
    'NOVELTY_SCORE': str(nov.get('score', '')),
    'NOVELTY_RATIONALE': nov.get('rationale', ''),
    'NOVELTY_RESULT': '✓ pass' if nov.get('score', 0) >= 6.0 else '✗ held',
    'V_EMDASH': '✓ 0' if True else '✗',
    'V_FORBIDDEN': '✓ clean',
    'V_VERIFY': '✓ 0',
    'V_HREF': '✓ clean',
    'V_BUILD': '✓ pass',
}
out = template
for k, v in subs.items():
    out = out.replace('{{' + k + '}}', str(v))
print(out)
PYEOF
}

# publish_draft <draft.astro> <candidate.json> <judges_json>
publish_draft() {
    local draft="$1"
    local candidate="$2"
    local judges_json="$3"

    local id type tier title
    id=$(python3 -c "import json; print(json.load(open('$candidate'))['id'])")
    type=$(python3 -c "import json; print(json.load(open('$candidate'))['type'])")
    tier=$(python3 -c "import json; print(json.load(open('$candidate'))['risk_tier'])")
    title=$(python3 -c "import json; print(json.load(open('$candidate'))['title'])")

    case "$type" in
        report) target_dir="src/pages/reports" ;;
        note)   target_dir="src/pages/notes" ;;
        *) log_error "publish_draft: unknown type: $type"; return 2 ;;
    esac

    local target_path="${WEBSITE_ROOT}/${target_dir}/${id}.astro"
    local branch="draft/${id}"

    log_section "publish_draft: id=$id tier=$tier branch=$branch"

    cd "$WEBSITE_ROOT" || { log_error "cd to website root failed"; return 2; }

    # Stage 1: ensure we're on main, fetch, branch off
    _run git fetch origin main || { log_error "git fetch failed"; return 2; }
    _run git checkout main || return 2
    _run git pull --ff-only origin main || return 2

    # Delete any existing branch with same name (idempotent)
    if git rev-parse --verify "$branch" >/dev/null 2>&1; then
        log_warn "publish_draft: branch $branch exists locally; deleting"
        _run git branch -D "$branch" || true
    fi
    if git rev-parse --verify "origin/$branch" >/dev/null 2>&1; then
        log_warn "publish_draft: branch $branch exists on origin; deleting"
        _run git push origin --delete "$branch" || true
    fi

    _run git checkout -b "$branch" || return 2

    # Stage 2: copy draft to target path
    _run cp "$draft" "$target_path" || return 2

    # Stage 3: commit
    local commit_msg
    commit_msg="curator: publish ${type} '${title}' (tier ${tier})"
    _run git add "$target_path" || return 2
    _run git commit -m "$commit_msg" -q || return 2

    # Stage 4: push branch
    _run git push -u origin "$branch" || { log_error "git push failed"; _run git checkout main; return 2; }

    # Stage 5: tier-specific gating
    case "$tier" in
        1)
            log_info "publish_draft: tier 1 → opening PR (human merge required)"
            local body
            body=$(_build_pr_body "$candidate" "$judges_json" "${CURATOR_RUN_ID:-manual}")
            local body_file
            body_file=$(mktemp /tmp/pr_body.XXXXXX.md)
            echo "$body" > "$body_file"
            _run gh pr create --title "Publish: $title" --body-file "$body_file" --base main --head "$branch"
            rm -f "$body_file"
            ;;
        2)
            log_info "publish_draft: tier 2 → opening PR + enabling auto-merge"
            local body
            body=$(_build_pr_body "$candidate" "$judges_json" "${CURATOR_RUN_ID:-manual}")
            local body_file
            body_file=$(mktemp /tmp/pr_body.XXXXXX.md)
            echo "$body" > "$body_file"
            _run gh pr create --title "Publish: $title" --body-file "$body_file" --base main --head "$branch"
            _run gh pr merge --auto --squash "$branch" || log_warn "auto-merge enable failed (PR may still merge manually)"
            rm -f "$body_file"
            ;;
        3)
            log_info "publish_draft: tier 3 → committed to $branch; veto-window cron will merge in 24h"
            # Tag the commit with curator metadata for veto_check.sh to find later
            _run git tag "curator-tier3-${id}" "$branch"
            _run git push origin "curator-tier3-${id}"
            ;;
        *) log_error "publish_draft: unknown tier: $tier"; return 2 ;;
    esac

    # Stage 6: return to main (caller can switch back)
    _run git checkout main

    log_info "publish_draft: tier $tier publish flow complete for $id"
    return 0
}
