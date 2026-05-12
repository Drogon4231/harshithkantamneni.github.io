#!/bin/bash
# Install the curator pre-commit hook into .git/hooks/.
#
# Symlinks tools/curator/hooks/pre-commit → .git/hooks/pre-commit so edits
# to the tracked source take effect immediately. Backs up any existing hook
# at .git/hooks/pre-commit.backup-<timestamp>.
#
# Run from the website repo root (or anywhere — paths are resolved
# relative to this script's location).

set -euo pipefail

SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WEBSITE_ROOT="$( cd "$SELF_DIR/../../.." && pwd )"
SOURCE="$SELF_DIR/pre-commit"
TARGET="$WEBSITE_ROOT/.git/hooks/pre-commit"

if [ ! -f "$SOURCE" ]; then
    echo "ERROR: $SOURCE not found" >&2
    exit 1
fi

mkdir -p "$WEBSITE_ROOT/.git/hooks"

if [ -e "$TARGET" ] && [ ! -L "$TARGET" ]; then
    BACKUP="${TARGET}.backup-$(date +%Y%m%d-%H%M%S)"
    mv "$TARGET" "$BACKUP"
    echo "backed up existing hook → $BACKUP"
fi

# Remove old symlink if present.
[ -L "$TARGET" ] && rm "$TARGET"

ln -s "$SOURCE" "$TARGET"
chmod +x "$SOURCE"
echo "installed: $TARGET → $SOURCE"
echo "next commit will run: bash $SOURCE (audits staged src/pages/ files)"
