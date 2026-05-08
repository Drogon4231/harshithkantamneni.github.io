#!/bin/bash
# Risk-tier classifier for publication candidates.
# Wraps MLX Qwen 2.5 3B with the classify_risk.txt prompt.
# Defaults to Tier 1 on any ambiguous output (safety-first).
#
# Usage:
#   . tools/curator/lib/classify.sh
#   tier=$(classify_candidate path/to/candidate.json)
#   echo "$tier"  # → 1, 2, or 3
#
# Returns the tier number on stdout. Logs reasoning to log file.

# Always compute CURATOR_DIR from this script's own location (don't trust env).
# This protects against stale CURATOR_DIR set by an unrelated earlier sourcing.
_CLASSIFY_SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURATOR_DIR="$( cd "$_CLASSIFY_SELF_DIR/.." && pwd )"
export CURATOR_DIR

[ -z "${CURATOR_LOG:-}" ] && {
    . "$_CLASSIFY_SELF_DIR/log.sh"
}

CLASSIFIER_MODEL="${CLASSIFIER_MODEL:-mlx-community/Qwen2.5-3B-Instruct-4bit}"
CLASSIFIER_PROMPT_TEMPLATE="${CURATOR_DIR}/prompts/classify_risk.txt"

# classify_candidate <candidate_json_path>
classify_candidate() {
    local candidate="$1"
    if [ ! -f "$candidate" ]; then
        log_error "classify_candidate: candidate file missing: $candidate"
        echo "1"  # safety-default
        return 1
    fi
    if [ ! -f "$CLASSIFIER_PROMPT_TEMPLATE" ]; then
        log_error "classify_candidate: prompt template missing: $CLASSIFIER_PROMPT_TEMPLATE"
        echo "1"
        return 1
    fi

    # Read candidate JSON content for substitution. We send a compact form
    # to keep the prompt short and the classifier focused on the relevant
    # fields (title, summary, type, lab, tags). Internal-only fields like
    # source_artifacts, scores, etc. are not relevant to classification.
    local candidate_compact
    candidate_compact=$(python3 -c "
import json, sys
d = json.load(open('$candidate'))
keep = {k: d[k] for k in ['title', 'summary', 'type', 'lab', 'tags'] if k in d}
print(json.dumps(keep, ensure_ascii=False))
")

    if [ -z "$candidate_compact" ]; then
        log_error "classify_candidate: failed to extract candidate fields"
        echo "1"
        return 1
    fi

    # Build prompt by substituting placeholder.
    local prompt
    prompt=$(python3 -c "
import sys
template = open('$CLASSIFIER_PROMPT_TEMPLATE').read()
print(template.replace('{{CANDIDATE_JSON}}', '''$candidate_compact'''))
")

    log_debug "classify_candidate: prompt length=$(echo -n "$prompt" | wc -c) chars"

    # Run MLX. --temp 0.0 for determinism. --max-tokens 8 (just need "Tier N").
    # Capture both stdout and stderr to detect infrastructure failures
    # distinctly from ambiguous-output failures.
    local mlx_full mlx_rc
    mlx_full=$(mlx_lm.generate \
        --model "$CLASSIFIER_MODEL" \
        --prompt "$prompt" \
        --max-tokens 8 \
        --temp 0.0 \
        2>&1)
    mlx_rc=$?

    if [ $mlx_rc -ne 0 ]; then
        # MLX itself failed (model load error, OOM, etc).
        # This is INFRASTRUCTURE failure, not ambiguous output.
        # Return exit code 3 to signal infra-fail vs. content-fail (which is exit 1).
        # Caller should hold the candidate, NOT proceed with default Tier 1.
        log_error "classify_candidate: MLX call FAILED (rc=$mlx_rc). This is infra failure, not ambiguity."
        log_error "classify_candidate: tail of MLX output:"
        echo "$mlx_full" | tail -5 | while IFS= read -r line; do log_error "  $line"; done
        echo ""  # empty stdout signals to caller
        return 3
    fi

    # Extract content between the ========== markers
    local raw_output
    raw_output=$(echo "$mlx_full" | sed -n '/^==========$/,/^==========$/p' | sed '1d;$d')

    if [ -z "$raw_output" ]; then
        log_error "classify_candidate: MLX produced no content between markers; treating as infra failure"
        log_error "classify_candidate: full output:"
        echo "$mlx_full" | head -10 | while IFS= read -r line; do log_error "  $line"; done
        echo ""
        return 3
    fi

    log_debug "classify_candidate: raw output: $(echo "$raw_output" | tr '\n' ' ')"

    # Parse "Tier N" pattern. If absent, this is genuine output ambiguity
    # (model didn't follow format) — default to Tier 1 with a loud warning.
    local tier
    tier=$(echo "$raw_output" | grep -oE 'Tier\s*[123]' | head -1 | grep -oE '[123]')

    if [ -z "$tier" ]; then
        log_warn "classify_candidate: model returned content but no parseable Tier ('$raw_output'); defaulting to Tier 1"
        tier=1
    fi

    log_info "classify_candidate: $(basename "$candidate") → Tier $tier"
    echo "$tier"
    return 0
}
