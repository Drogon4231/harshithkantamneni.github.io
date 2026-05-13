#!/bin/bash
# Reject a candidate currently in 'awaiting_review' → mark held with the
# operator's reason. Pending draft files are cleaned up.
#
# Usage:
#   bash tools/curator/reject.sh <id> [reason]
#
# Default reason: "operator rejected via dashboard".
# After rejection: cli.sh retry <id> sends it back to pending for a re-run.

set -euo pipefail

CURATOR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
. "$CURATOR_DIR/lib/log.sh"

TARGET_ID="${1:-}"
REASON="${2:-operator rejected via dashboard}"
if [ -z "$TARGET_ID" ]; then
    echo "usage: $0 <id> [reason]" >&2
    exit 2
fi

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
    log_error "reject: no candidate with id=$TARGET_ID"
    exit 1
fi

CANDIDATE="$CANDIDATE" REASON="$REASON" python3 <<'PYEOF'
import os, json
p = os.environ['CANDIDATE']
d = json.load(open(p))
d['curator_state'] = 'held'
d['held_reason'] = os.environ['REASON']
d.pop('pending_draft', None)
d.pop('awaiting_review_at', None)
open(p, 'w').write(json.dumps(d, indent=2))
PYEOF

rm -f "$CURATOR_DIR/pending_drafts/${TARGET_ID}.astro" \
      "$CURATOR_DIR/pending_drafts/${TARGET_ID}.judges.json" \
      "$CURATOR_DIR/pending_drafts/${TARGET_ID}.hackernews.txt" \
      "$CURATOR_DIR/pending_drafts/${TARGET_ID}.linkedin.txt"
log_info "reject: $TARGET_ID → held; reason: $REASON"
