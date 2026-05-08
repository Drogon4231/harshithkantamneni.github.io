#!/bin/bash
# Provenance frontmatter injector.
# Adds a JSX comment block at the top of an Astro draft (right after the
# frontmatter --- block) recording the curator metadata so any published
# piece traces back to its origin.
#
# Per AutoResearchClaw / AutoRecLab: every published piece carries
# {lab, cycle_id, source_artifacts, drafted_by, judged_by (with scores),
# risk_tier, curator_run, cost_local_seconds}.
#
# Usage:
#   . tools/curator/lib/provenance.sh
#   inject_provenance <draft.astro> <candidate.json> <judges_json> <cost_seconds>
#   # modifies draft.astro in place, adding the provenance block

_PROV_SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURATOR_DIR="$( cd "$_PROV_SELF_DIR/.." && pwd )"
export CURATOR_DIR

[ -z "${CURATOR_LOG:-}" ] && {
    . "$_PROV_SELF_DIR/log.sh"
}

# inject_provenance <draft> <candidate> <judges_json> [cost_seconds]
inject_provenance() {
    local draft="$1"
    local candidate="$2"
    local judges_json="$3"
    local cost_seconds="${4:-0}"

    if [ ! -f "$draft" ] || [ ! -f "$candidate" ]; then
        log_error "inject_provenance: missing draft or candidate"
        return 1
    fi

    log_info "inject_provenance: $(basename "$draft")"

    # Pass bash vars to Python via env to avoid heredoc-substitution issues.
    DRAFT_PATH="$draft" \
    CANDIDATE_PATH="$candidate" \
    JUDGES_JSON="$judges_json" \
    COST_SECONDS="$cost_seconds" \
    RUN_ID="${CURATOR_RUN_ID:-manual}" \
    python3 <<'PYEOF'
import json, re, sys, datetime, os

draft_path = os.environ['DRAFT_PATH']
candidate = json.load(open(os.environ['CANDIDATE_PATH']))
judges = json.loads(os.environ['JUDGES_JSON'])
cost_seconds = os.environ.get('COST_SECONDS', '0')
run_id = os.environ.get('RUN_ID', 'manual')

voice = judges.get('voice', {})
fact = judges.get('factcheck', {})
nov = judges.get('novelty', {})

src_lines = []
for sa in candidate['source_artifacts']:
    if isinstance(sa, dict):
        src_lines.append(f"      - lab: {sa['lab']}, path: {sa['path']}")
    else:
        src_lines.append(f"      - {sa}")
src_block = "\n".join(src_lines)

ts_iso = datetime.datetime.now(datetime.timezone.utc).isoformat()

block = f"""{{/*
  curator-provenance:
    lab: {candidate['lab']}
    type: {candidate['type']}
    id: {candidate['id']}
    ratified_at: {candidate['ratified_at']}
    ratified_date: {candidate.get('ratified_date', '')}
    risk_tier: {candidate.get('risk_tier', '')}
    source_artifacts:
{src_block}
    drafted_by: claude-opus-4-7 via claude-cli
    judged_by:
      voice: mlx-community/Qwen2.5-Coder-14B-Instruct-4bit (score {voice.get('score', '?')}/10)
      factcheck: deterministic numeric (verified {fact.get('verified_count', '?')}/{fact.get('draft_numbers_total', '?')})
      novelty: mlx-community/Qwen2.5-7B-Instruct-4bit (score {nov.get('score', '?')}/10)
    curator_run: {run_id}
    curator_run_iso: {ts_iso}
    cost_local_seconds: {cost_seconds}
*/}}
"""

content = open(draft_path).read()
m = re.match(r'(---\n[\s\S]*?\n---\n?)([\s\S]*)', content)
if not m:
    sys.exit("inject_provenance: no frontmatter found in draft")

frontmatter = m.group(1)
body = m.group(2)

# Strip any prior provenance block
body = re.sub(r'\{/\*\s*curator-provenance:[\s\S]*?\*/\}\s*\n*', '', body)

new_content = frontmatter + "\n" + block + "\n" + body.lstrip("\n")
open(draft_path, "w").write(new_content)
PYEOF
    local rc=$?
    if [ $rc -ne 0 ]; then
        log_error "inject_provenance: python failed (rc=$rc)"
        return $rc
    fi

    return 0
}
