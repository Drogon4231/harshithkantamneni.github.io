#!/bin/bash
# Tier-3 veto-window check.
# Looks for branches tagged `curator-tier3-*` whose tag is older than 24
# hours and merges them into main. Should run as a separate cron (hourly,
# so newly-eligible branches merge within the hour after the threshold).
#
# Usage:
#   bash tools/curator/veto_check.sh

set -euo pipefail

CURATOR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
WEBSITE_ROOT="$( cd "$CURATOR_DIR/../.." && pwd )"

. "$CURATOR_DIR/lib/log.sh"

VETO_HOURS="${VETO_HOURS:-24}"

cd "$WEBSITE_ROOT"

git fetch --tags origin 2>/dev/null || true
git fetch origin main 2>/dev/null || true

# List all curator-tier3-* tags. Use for-loop instead of mapfile for
# bash 3.2 compatibility (default macOS bash).
TAG_LIST=$(git tag --list 'curator-tier3-*' 2>/dev/null)

if [ -z "$TAG_LIST" ]; then
    log_info "veto_check: no tier-3 tags pending"
    exit 0
fi

NOW_EPOCH=$(date +%s)
THRESHOLD=$((NOW_EPOCH - VETO_HOURS * 3600))

for tag in $TAG_LIST; do
    # Get the commit timestamp of the tag (epoch seconds)
    tag_epoch=$(git log -1 --format=%ct "$tag" 2>/dev/null || echo 0)

    if [ "$tag_epoch" -ge "$THRESHOLD" ]; then
        age_hours=$(( (NOW_EPOCH - tag_epoch) / 3600 ))
        log_info "veto_check: $tag age=${age_hours}h, threshold=${VETO_HOURS}h → wait"
        continue
    fi

    # Branch name from tag: curator-tier3-<id> → draft/<id>
    id="${tag#curator-tier3-}"
    branch="draft/${id}"

    # Check the branch still exists on origin
    if ! git ls-remote --heads origin "$branch" | grep -q .; then
        log_warn "veto_check: branch $branch no longer on origin (vetoed?), skipping; deleting tag"
        git tag -d "$tag" 2>/dev/null || true
        git push origin ":refs/tags/$tag" 2>/dev/null || true
        continue
    fi

    log_info "veto_check: $tag past threshold, merging $branch into main"

    # Squash-merge via gh CLI (creates a PR + immediate merge)
    # Alternative: direct merge + push, but squash via PR keeps history clean
    pr_url=$(gh pr create --base main --head "$branch" \
        --title "Tier-3 publish: $id (veto-window expired)" \
        --body "Auto-merged after ${VETO_HOURS}h veto window. No veto received." 2>/dev/null \
        || gh pr view "$branch" --json url -q .url 2>/dev/null \
        || echo "")

    if [ -z "$pr_url" ]; then
        log_error "veto_check: could not create or find PR for $branch; skipping"
        continue
    fi

    # Merge it
    gh pr merge --squash --delete-branch "$pr_url" 2>&1 | head -3 || {
        log_error "veto_check: gh pr merge failed for $pr_url"
        continue
    }

    # Clean up the tag
    git tag -d "$tag" 2>/dev/null || true
    git push origin ":refs/tags/$tag" 2>/dev/null || true
    log_info "veto_check: $branch merged"
done

log_info "veto_check: pass complete"
