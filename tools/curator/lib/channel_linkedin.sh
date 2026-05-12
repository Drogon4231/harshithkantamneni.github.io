#!/bin/bash
# LinkedIn teaser generator. Single narrow LLM call.
# Reads the published Astro page, extracts prose (stripping markup),
# generates a 200-300 word teaser via Claude --print, validates basic
# constraints, writes to channel_drafts/linkedin/<id>.txt.
#
# Does NOT auto-post to LinkedIn. The operator copy-pastes when ready.
# (LinkedIn API is restrictive; manual post + automated draft is the
# right shape.)

_LI_SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURATOR_DIR="$( cd "$_LI_SELF_DIR/.." && pwd )"
WEBSITE_ROOT="$( cd "$CURATOR_DIR/../.." && pwd )"
export CURATOR_DIR

[ -z "${CURATOR_LOG:-}" ] && {
    . "$_LI_SELF_DIR/log.sh"
}

SITE_BASE_URL="${SITE_BASE_URL:-https://drogon4231.github.io/harshithkantamneni.github.io}"

# Extract prose from an Astro page. Strips JSX tags, frontmatter, JSX
# expressions, and astro-cid attributes.
_extract_prose() {
    local astro_file="$1"
    python3 <<PYEOF
import re
text = open("$astro_file").read()
# Strip frontmatter (first --- block)
text = re.sub(r'^---\n[\s\S]*?\n---\n?', '', text, count=1)
# Strip JSX comment blocks {/* ... */}
text = re.sub(r'\{/\*[\s\S]*?\*/\}', '', text)
# Strip JSX expression blocks {...}
text = re.sub(r'\{[^{}]*?\}', '', text)
# Strip HTML/JSX tags
text = re.sub(r'<[^>]+>', ' ', text)
# Normalize whitespace
text = re.sub(r'[ \t]+', ' ', text)
text = re.sub(r'\n\s*\n', '\n\n', text)
print(text.strip())
PYEOF
}

# channel_linkedin <candidate.json>
# Writes channel_drafts/linkedin/<id>.txt. Returns 0 on success.
channel_linkedin() {
    local candidate="$1"
    if [ ! -f "$candidate" ]; then
        log_error "channel_linkedin: candidate missing: $candidate"
        return 1
    fi

    local id type title summary
    id=$(python3 -c "import json; print(json.load(open('$candidate'))['id'])")
    type=$(python3 -c "import json; print(json.load(open('$candidate'))['type'])")
    title=$(python3 -c "import json; print(json.load(open('$candidate'))['title'])")
    summary=$(python3 -c "import json; print(json.load(open('$candidate'))['summary'])")

    # Resolve the published Astro file to extract prose from
    local subpath astro_path target_url
    case "$type" in
        report) subpath="reports" ;;
        note)   subpath="notes" ;;
        *) log_error "channel_linkedin: unknown type: $type"; return 1 ;;
    esac
    astro_path="${WEBSITE_ROOT}/src/pages/${subpath}/${id}.astro"
    target_url="${SITE_BASE_URL}/${subpath}/${id}"

    if [ ! -f "$astro_path" ]; then
        log_error "channel_linkedin: published Astro file missing: $astro_path"
        return 1
    fi

    log_info "channel_linkedin: extracting prose from $astro_path"
    local prose
    prose=$(_extract_prose "$astro_path")
    if [ -z "$prose" ]; then
        log_error "channel_linkedin: extracted prose is empty"
        return 1
    fi

    # Build narrow prompt (voice anchor + extracted prose + URL — no
    # source artifacts, no forbidden phrases, no JSON metadata clutter).
    local voice_md="$CURATOR_DIR/voice/linkedin.md"
    if [ ! -f "$voice_md" ]; then
        log_error "channel_linkedin: voice anchor missing: $voice_md"
        return 1
    fi

    local prompt
    prompt=$(VOICE_PATH="$voice_md" TITLE="$title" URL="$target_url" TYPE="$type" PROSE="$prose" python3 <<'PYEOF'
import os
template = open(os.environ['CURATOR_DIR'] + '/prompts/channel_linkedin.txt').read()
voice = open(os.environ['VOICE_PATH']).read()
print(
    template
    .replace('{{VOICE_MD}}', voice)
    .replace('{{TITLE}}', os.environ['TITLE'])
    .replace('{{URL}}', os.environ['URL'])
    .replace('{{TYPE}}', os.environ['TYPE'])
    .replace('{{PROSE}}', os.environ['PROSE'])
)
PYEOF
)

    log_info "channel_linkedin: prompt $(echo -n "$prompt" | wc -c) chars; calling claude --print --model opus"

    # Single narrow Claude call.
    local teaser rc
    teaser=$(echo "$prompt" | claude --print --model opus --dangerously-skip-permissions 2>/dev/null)
    rc=$?

    if [ $rc -ne 0 ] || [ -z "$teaser" ]; then
        log_error "channel_linkedin: claude failed (rc=$rc)"
        return 1
    fi

    # Validate: 200-300 words, no em-dashes, no obvious cargo-cult.
    local word_count em_dashes
    word_count=$(echo "$teaser" | wc -w | tr -d ' ')
    em_dashes=$(echo "$teaser" | grep -- "—" | wc -l | tr -d ' ')

    if [ "$em_dashes" -gt 0 ]; then
        log_warn "channel_linkedin: $em_dashes em-dash(es) present; flagged but not blocking"
    fi
    if [ "$word_count" -lt 150 ] || [ "$word_count" -gt 350 ]; then
        log_warn "channel_linkedin: word count $word_count is outside 150-350 range; flagged but not blocking"
    fi

    # Forbidden phrase check — delegate to the word-boundary helper
    # (which properly filters comments and blank lines from the phrase file).
    [ "$(type -t forbidden_check)" = "function" ] || . "$CURATOR_DIR/lib/forbidden_check.sh"
    local teaser_tmpfile
    teaser_tmpfile=$(mktemp /tmp/linkedin_teaser.XXXXXX.txt)
    echo "$teaser" > "$teaser_tmpfile"
    local forbidden_hits=0
    if ! forbidden_check "$teaser_tmpfile" "$CURATOR_DIR/forbidden_phrases.txt" 2>/dev/null; then
        # forbidden_check returns nonzero if hits found; count by re-grepping log
        forbidden_hits=$(forbidden_check "$teaser_tmpfile" "$CURATOR_DIR/forbidden_phrases.txt" 2>&1 | grep -c "HIT:")
    fi
    rm -f "$teaser_tmpfile"
    if [ "$forbidden_hits" -gt 0 ]; then
        log_warn "channel_linkedin: $forbidden_hits forbidden-phrase hit(s); flagged but not blocking"
    fi

    # Write output file with metadata header
    local out_file="${CURATOR_DIR}/channel_drafts/linkedin/${id}.txt"
    mkdir -p "$(dirname "$out_file")"

    cat > "$out_file" <<EOF
LINKEDIN TEASER (paste-ready)
=============================

ID:          ${id}
Type:        ${type}
URL:         ${target_url}
Word count:  ${word_count}
Em-dashes:   ${em_dashes}
Forbidden:   ${forbidden_hits}

──────── post body below ────────

${teaser}

──────── end ────────

Operator notes:
- Paste the post body (between the dashed lines) into LinkedIn's compose box.
- LinkedIn truncates at the first ~210 characters in feed. Verify the hook lands in that window.
- LinkedIn discourages link-only posts. The CTA at the end is correct shape.
- Posting timing: weekday 8-10am local time tends to outperform other windows for technical content.
EOF

    log_info "channel_linkedin: teaser written to $out_file (${word_count} words)"
    return 0
}
