#!/bin/bash
# Revise a pending draft using operator notes as revision instructions.
# Called by the dashboard's "apply notes" button.
#
# Usage:
#   bash tools/curator/revise.sh <id> <notes_file>
#
# notes_file: path to a text file containing the operator's instructions.
# (We pass via file rather than CLI arg to allow multi-line + special chars.)

set -euo pipefail

CURATOR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$CURATOR_DIR/lib/log.sh"

TARGET_ID="${1:-}"
NOTES_FILE="${2:-}"
if [ -z "$TARGET_ID" ] || [ -z "$NOTES_FILE" ]; then
    echo "usage: $0 <id> <notes_file>" >&2
    exit 2
fi

DRAFT_FILE="$CURATOR_DIR/pending_drafts/${TARGET_ID}.astro"
if [ ! -f "$DRAFT_FILE" ]; then
    log_error "revise: pending draft missing: $DRAFT_FILE"
    exit 1
fi
if [ ! -f "$NOTES_FILE" ]; then
    log_error "revise: notes file missing: $NOTES_FILE"
    exit 1
fi

TEMPLATE="$CURATOR_DIR/prompts/revise.txt"
if [ ! -f "$TEMPLATE" ]; then
    log_error "revise: template missing: $TEMPLATE"
    exit 1
fi

log_section "revise: $TARGET_ID"

PROMPT=$(DRAFT_FILE="$DRAFT_FILE" NOTES_FILE="$NOTES_FILE" TEMPLATE="$TEMPLATE" python3 <<'PYEOF'
import os
draft = open(os.environ['DRAFT_FILE']).read()
notes = open(os.environ['NOTES_FILE']).read()
template = open(os.environ['TEMPLATE']).read()
print(template.replace('{{DRAFT}}', draft).replace('{{NOTES}}', notes))
PYEOF
)

PROMPT_LEN=${#PROMPT}
log_info "revise: prompt $PROMPT_LEN chars; calling claude --print --model opus"

REVISED=$(echo "$PROMPT" | claude --print --model opus --dangerously-skip-permissions 2>/dev/null || true)

if [ -z "$REVISED" ]; then
    log_error "revise: claude returned empty"
    exit 1
fi

# Snapshot the current draft to .prev BEFORE replacing (enables one-level undo).
cp "$DRAFT_FILE" "${DRAFT_FILE}.prev"

# Atomically replace the pending draft file.
TMP=$(mktemp "${CURATOR_DIR}/pending_drafts/.${TARGET_ID}.XXXXXX")
printf "%s" "$REVISED" > "$TMP"
mv "$TMP" "$DRAFT_FILE"

log_info "revise: $TARGET_ID → updated (${#REVISED} chars; .prev saved for undo)"

# Regenerate channel drafts since the main draft changed (any LinkedIn teaser
# extracted from the old prose is now stale). Best-effort; failures non-blocking.
CANDIDATE_FILE=""
for dir in "$HOME/Desktop/Fun/lab/publish_candidates" "$HOME/Desktop/AGI/data/publish_candidates"; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.json; do
        [ -f "$f" ] || continue
        FID=$(F="$f" python3 -c "import os, json; print(json.load(open(os.environ['F'])).get('id',''))" 2>/dev/null)
        if [ "$FID" = "$TARGET_ID" ]; then
            CANDIDATE_FILE="$f"
            break 2
        fi
    done
done

if [ -n "$CANDIDATE_FILE" ]; then
    . "$CURATOR_DIR/lib/channel_hackernews.sh"
    . "$CURATOR_DIR/lib/channel_linkedin.sh"
    CHANNELS=$(CANDIDATE="$CANDIDATE_FILE" python3 -c "import os, json; print(' '.join(json.load(open(os.environ['CANDIDATE'])).get('channels', ['website'])))" 2>/dev/null || echo "website")
    for ch in $CHANNELS; do
        case "$ch" in
            hackernews)
                channel_hackernews "$CANDIDATE_FILE" \
                    "${CURATOR_DIR}/pending_drafts/${TARGET_ID}.hackernews.txt" \
                    || log_warn "revise: HN regen failed (non-blocking)"
                ;;
            linkedin)
                channel_linkedin "$CANDIDATE_FILE" "$DRAFT_FILE" \
                    "${CURATOR_DIR}/pending_drafts/${TARGET_ID}.linkedin.txt" \
                    || log_warn "revise: LinkedIn regen failed (non-blocking)"
                ;;
        esac
    done
fi
