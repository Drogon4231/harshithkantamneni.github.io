#!/bin/bash
# HN suggester. Fully deterministic — no LLM call.
# Generates a paste-ready Hacker News submission suggestion (title + URL)
# and writes it to channel_drafts/hackernews/<id>.txt + a single log line.
#
# The operator manually submits to HN when timing is right. HN is hostile
# to automated submissions; this script never posts.

_HN_SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURATOR_DIR="$( cd "$_HN_SELF_DIR/.." && pwd )"
export CURATOR_DIR

[ -z "${CURATOR_LOG:-}" ] && {
    . "$_HN_SELF_DIR/log.sh"
}

HN_USERNAME="${HN_USERNAME:-Drogon4231}"
SITE_BASE_URL="${SITE_BASE_URL:-https://drogon4231.github.io/harshithkantamneni.github.io}"

# channel_hackernews <candidate.json>
# Output: writes channel_drafts/hackernews/<id>.txt, returns 0
channel_hackernews() {
    local candidate="$1"
    if [ ! -f "$candidate" ]; then
        log_error "channel_hackernews: candidate missing: $candidate"
        return 1
    fi

    local id type title summary
    id=$(python3 -c "import json; print(json.load(open('$candidate'))['id'])")
    type=$(python3 -c "import json; print(json.load(open('$candidate'))['type'])")
    title=$(python3 -c "import json; print(json.load(open('$candidate'))['title'])")
    summary=$(python3 -c "import json; print(json.load(open('$candidate'))['summary'])")

    # HN URL: report or note in the right path
    local subpath
    case "$type" in
        report) subpath="reports" ;;
        note)   subpath="notes" ;;
        *) log_error "channel_hackernews: unknown type: $type"; return 1 ;;
    esac
    local target_url="${SITE_BASE_URL}/${subpath}/${id}"

    # Generate suggested HN title. HN convention:
    # - Drop "in autonomous engineering systems" suffixes (too academic)
    # - Drop colons followed by long sub-titles (HN truncates titles)
    # - Hooky-but-honest works best ("Show HN" prefix optional)
    # Deterministic transforms only — no LLM rewrite.
    local hn_title
    hn_title=$(python3 -c "
title = '$title'.strip()
# If title is much over 80 chars, suggest a shorter form
# (HN UI truncates around 80, search/email crops to 80)
if len(title) > 80:
    # Try cutting at first colon
    if ':' in title:
        head = title.split(':', 1)[0].strip()
        if len(head) >= 30 and len(head) <= 80:
            title = head
print(title)
")

    local out_file="${CURATOR_DIR}/channel_drafts/hackernews/${id}.txt"
    mkdir -p "$(dirname "$out_file")"

    cat > "$out_file" <<EOF
HACKER NEWS SUBMISSION
======================

Submit at: https://news.ycombinator.com/submit
Account:   ${HN_USERNAME}

Suggested title (${#hn_title} chars):
${hn_title}

URL:
${target_url}

Summary (for context, not the submission):
${summary}

Timing guidance:
- Best submission window: weekday 8-10am Eastern (peak HN traffic)
- Avoid weekends and major US holidays
- If a related HN thread is already hot, hold for a day or two

Operator note:
- Don't submit immediately after publishing the site. Wait at least 1-2
  days so any post-publish edits land first.
- Don't submit if you've already submitted another piece in the last
  ~5 days (audience overlap, reduced ranking).
EOF

    log_info "channel_hackernews: suggestion written to $out_file"
    log_info "channel_hackernews: TITLE='${hn_title}' URL=${target_url}"

    # Also emit a daily-log summary line that's easy to grep
    log_info "HN_SUGGEST: @${HN_USERNAME} submit \"${hn_title}\" → ${target_url}"

    return 0
}
