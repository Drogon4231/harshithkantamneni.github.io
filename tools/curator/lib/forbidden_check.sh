#!/bin/bash
# Forbidden-phrase checker for the curator validator.
# Uses word-boundary matching for single-word entries; substring match for
# multi-word entries. Single-word boundary match prevents false positives
# like "world-class" matching inside "Hello-World-class" (a deliberate user
# pun in published prose).
#
# Usage:
#   . tools/curator/lib/forbidden_check.sh
#   forbidden_check <draft_file> <phrases_file>
#   # returns 0 if clean, nonzero if any phrase matched
#   # logs each match to stderr

[ -z "${CURATOR_LOG:-}" ] && {
    SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    . "$SELF_DIR/log.sh"
}

forbidden_check() {
    local draft="$1"
    local phrases_file="${2:-${CURATOR_DIR}/forbidden_phrases.txt}"

    if [ ! -f "$draft" ]; then
        log_error "forbidden_check: draft file missing: $draft"
        return 2
    fi
    if [ ! -f "$phrases_file" ]; then
        log_error "forbidden_check: phrases file missing: $phrases_file"
        return 2
    fi

    # Read phrases, strip comments and blanks
    local hits=0
    while IFS= read -r phrase; do
        # skip comments and blanks
        [[ "$phrase" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${phrase// }" ]] && continue

        # Single-word phrases use word-boundary match (\b around the term).
        # Multi-word phrases use substring (already specific enough).
        local matched=0
        if [[ "$phrase" =~ \  ]]; then
            # Multi-word: case-insensitive fixed-string substring
            if grep -iqF "$phrase" "$draft"; then
                matched=1
            fi
        else
            # Single-word: case-insensitive word-boundary match.
            # GNU/macOS grep -w uses \b boundaries; works for hyphenated
            # words too (treats hyphen as word break).
            if grep -iwq -- "$phrase" "$draft"; then
                matched=1
            fi
        fi

        if [ "$matched" -eq 1 ]; then
            log_warn "forbidden_check: HIT: '$phrase' in $draft"
            hits=$((hits+1))
        fi
    done < "$phrases_file"

    if [ "$hits" -gt 0 ]; then
        log_error "forbidden_check: $hits phrase(s) matched"
        return 1
    fi
    log_info "forbidden_check: clean ($draft)"
    return 0
}
