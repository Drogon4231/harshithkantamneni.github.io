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

# Atomically replace the pending draft file.
TMP=$(mktemp "${CURATOR_DIR}/pending_drafts/.${TARGET_ID}.XXXXXX")
printf "%s" "$REVISED" > "$TMP"
mv "$TMP" "$DRAFT_FILE"

log_info "revise: $TARGET_ID → updated (${#REVISED} chars)"
