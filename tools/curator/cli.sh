#!/bin/bash
# Operator interface to the curator pipeline.
#
# Usage:
#   bash tools/curator/cli.sh <verb> [args]
#
# Verbs:
#   status           One-pager: queue, runs, held, channel drafts
#   queue            List all non-published candidates with their state
#   held             List held candidates with reasons
#   retry <id>       Reset held candidate → pending (will run on next pass)
#   (veto removed 2026-05-13 — review-gate replaces the 24h auto-merge window)
#   tail             Tail today's curator log
#   runs [N]         Summarize last N runs across all logs (default 10)
#   help             Show usage
#
# See OPERATING.md for edit-locations cheat sheet.

set -euo pipefail

_CLI_SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CURATOR_DIR="$_CLI_SELF_DIR"
WEBSITE_ROOT="$( cd "$CURATOR_DIR/../.." && pwd )"

HIVE_MANIFEST_DIR="$HOME/Desktop/Fun/lab/publish_candidates"
AGI_MANIFEST_DIR="$HOME/Desktop/AGI/data/publish_candidates"

# ── Color helpers (suppressed if not a tty) ────────────────────────────────
if [ -t 1 ]; then
    C_DIM=$'\033[2m'
    C_BOLD=$'\033[1m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
    C_CYAN=$'\033[36m'
    C_OFF=$'\033[0m'
else
    C_DIM='' C_BOLD='' C_GREEN='' C_YELLOW='' C_RED='' C_CYAN='' C_OFF=''
fi

# ── Helpers ────────────────────────────────────────────────────────────────

# Print "LAB FILEPATH" lines for every manifest across both labs.
_iter_candidates() {
    local dir lab f
    for dir in "$HIVE_MANIFEST_DIR" "$AGI_MANIFEST_DIR"; do
        [ -d "$dir" ] || continue
        case "$dir" in
            *Fun*) lab="HIVE" ;;
            *AGI*) lab="AGI" ;;
            *)     lab="?" ;;
        esac
        for f in "$dir"/*.json; do
            [ -f "$f" ] || continue
            echo "$lab $f"
        done
    done
}

# Read one field from a manifest JSON safely (returns "" on error).
_get_field() {
    F="$1" K="$2" python3 -c "
import os, json
try:
    d = json.load(open(os.environ['F']))
    v = d.get(os.environ['K'], '')
    print(v if v is not None else '')
except Exception:
    print('')
" 2>/dev/null
}

# Atomically update a single field in a manifest JSON.
_set_field() {
    F="$1" K="$2" V="$3" python3 <<'PYEOF'
import os, json
p = os.environ['F']
d = json.load(open(p))
v = os.environ['V']
d[os.environ['K']] = v if v != '' else None
if d.get(os.environ['K']) is None:
    d.pop(os.environ['K'], None)
open(p, 'w').write(json.dumps(d, indent=2))
PYEOF
}

# Find the manifest file path for a given id. Echoes path or "".
_find_by_id() {
    local target="$1"
    local lab f id
    while IFS=' ' read -r lab f; do
        [ -z "$lab" ] && continue
        id=$(_get_field "$f" "id")
        if [ "$id" = "$target" ]; then
            echo "$f"
            return 0
        fi
    done < <(_iter_candidates)
    echo ""
}

# ── Verbs ──────────────────────────────────────────────────────────────────

cli_status() {
    echo "${C_BOLD}── curator status ──────────────────────────────────────${C_OFF}"
    echo ""
    echo "  pipeline trigger: ${C_DIM}manual — run 'bash tools/curator/run.sh'${C_OFF}"

    # Queue
    local pending=0 processing=0 awaiting=0 held=0 published=0 vetoed=0 unknown=0
    local lab f state
    while IFS=' ' read -r lab f; do
        [ -z "$lab" ] && continue
        state=$(_get_field "$f" "curator_state")
        case "$state" in
            pending)          pending=$((pending + 1)) ;;
            processing)       processing=$((processing + 1)) ;;
            awaiting_review)  awaiting=$((awaiting + 1)) ;;
            held)             held=$((held + 1)) ;;
            published)        published=$((published + 1)) ;;
            vetoed)           vetoed=$((vetoed + 1)) ;;
            *)                unknown=$((unknown + 1)) ;;
        esac
    done < <(_iter_candidates)

    echo ""
    echo "  queue:"
    echo "    pending          ${pending}"
    if [ "$processing" -gt 0 ]; then
        echo "    processing       ${C_YELLOW}${processing} (STUCK — last run interrupted?)${C_OFF}"
    else
        echo "    processing       ${processing}"
    fi
    if [ "$awaiting" -gt 0 ]; then
        echo "    awaiting_review  ${C_CYAN}${awaiting}${C_OFF}  (review in dashboard: cli.sh ui)"
    else
        echo "    awaiting_review  ${awaiting}"
    fi
    if [ "$held" -gt 0 ]; then
        echo "    held             ${C_YELLOW}${held}${C_OFF}  (see: cli.sh held)"
    else
        echo "    held             ${held}"
    fi
    echo "    published        ${published}"
    [ "$vetoed" -gt 0 ] && echo "    vetoed           ${vetoed}"
    [ "$unknown" -gt 0 ] && echo "    ${C_RED}unknown          ${unknown}${C_OFF}"

    # Channel drafts pending operator paste
    local hn_drafts li_drafts
    hn_drafts=$(find "$CURATOR_DIR/channel_drafts/hackernews" -name '*.txt' -type f 2>/dev/null | wc -l | tr -d ' ')
    li_drafts=$(find "$CURATOR_DIR/channel_drafts/linkedin" -name '*.txt' -type f 2>/dev/null | wc -l | tr -d ' ')
    echo ""
    echo "  channel drafts (pending operator paste):"
    echo "    hackernews    ${hn_drafts}"
    echo "    linkedin      ${li_drafts}"

    # Today's log
    local today_log="${CURATOR_DIR}/log/$(date +%Y-%m-%d).log"
    echo ""
    if [ -f "$today_log" ]; then
        echo "  today's log:  $today_log"
        local last_end last_start
        last_end=$(grep "curator run end" "$today_log" 2>/dev/null | tail -1 || true)
        last_start=$(grep "curator run start" "$today_log" 2>/dev/null | tail -1 || true)
        if [ -n "$last_end" ]; then
            echo "    last run:     ended cleanly"
        elif [ -n "$last_start" ]; then
            echo "    last run:     ${C_YELLOW}started but no end logged (interrupted?)${C_OFF}"
        else
            echo "    last run:     no run today yet"
        fi
    else
        echo "  today's log:  ${C_DIM}(none — curator hasn't fired today)${C_OFF}"
    fi
    echo ""
}

cli_queue() {
    local lab f state id type tier title
    local rows=0
    printf "%-6s  %-32s  %-7s  %-4s  %-11s  %s\n" "LAB" "ID" "TYPE" "TIER" "STATE" "TITLE"
    printf "%-6s  %-32s  %-7s  %-4s  %-11s  %s\n" \
        "------" "--------------------------------" "-------" "----" "-----------" "-----"
    while IFS=' ' read -r lab f; do
        [ -z "$lab" ] && continue
        state=$(_get_field "$f" "curator_state")
        # Skip terminal states
        case "$state" in published|vetoed) continue ;; esac
        id=$(_get_field "$f" "id")
        type=$(_get_field "$f" "type")
        tier=$(_get_field "$f" "risk_tier")
        title=$(_get_field "$f" "title")
        [ ${#title} -gt 50 ] && title="${title:0:47}..."
        printf "%-6s  %-32s  %-7s  %-4s  %-11s  %s\n" \
            "$lab" "$id" "$type" "${tier:--}" "$state" "$title"
        rows=$((rows + 1))
    done < <(_iter_candidates)
    if [ "$rows" -eq 0 ]; then
        echo "  ${C_DIM}(no candidates in queue)${C_OFF}"
    fi
}

cli_held() {
    local lab f state id reason title
    local rows=0
    while IFS=' ' read -r lab f; do
        [ -z "$lab" ] && continue
        state=$(_get_field "$f" "curator_state")
        [ "$state" = "held" ] || continue
        id=$(_get_field "$f" "id")
        reason=$(_get_field "$f" "held_reason")
        title=$(_get_field "$f" "title")
        echo "${C_YELLOW}[$lab]${C_OFF} ${C_BOLD}$id${C_OFF}"
        echo "  title:   $title"
        echo "  reason:  ${C_RED}$reason${C_OFF}"
        echo "  retry:   bash tools/curator/cli.sh retry $id"
        echo ""
        rows=$((rows + 1))
    done < <(_iter_candidates)
    if [ "$rows" -eq 0 ]; then
        echo "${C_GREEN}no held candidates${C_OFF}"
    fi
}

cli_retry() {
    local target="${1:-}"
    if [ -z "$target" ]; then
        echo "usage: cli.sh retry <id>" >&2
        return 2
    fi
    local found state
    found=$(_find_by_id "$target")
    if [ -z "$found" ]; then
        echo "${C_RED}not found:${C_OFF} no candidate with id=$target" >&2
        return 1
    fi
    state=$(_get_field "$found" "curator_state")
    if [ "$state" != "held" ]; then
        echo "${C_YELLOW}refusing:${C_OFF} candidate state is '$state', not 'held'." >&2
        echo "  (To force-reset, manually edit $found)" >&2
        return 1
    fi
    F="$found" python3 <<'PYEOF'
import os, json
p = os.environ['F']
d = json.load(open(p))
d['curator_state'] = 'pending'
d.pop('held_reason', None)
open(p, 'w').write(json.dumps(d, indent=2))
PYEOF
    echo "${C_GREEN}retry queued:${C_OFF} $target → pending"
    echo "  (will run on next curator pass; trigger manually: bash tools/curator/run.sh)"
}

cli_tail() {
    local today_log="${CURATOR_DIR}/log/$(date +%Y-%m-%d).log"
    if [ ! -f "$today_log" ]; then
        echo "no log for today: $today_log" >&2
        echo "(showing newest log instead)" >&2
        local newest
        newest=$(ls -1t "$CURATOR_DIR"/log/2*.log 2>/dev/null | head -1)
        [ -n "$newest" ] && exec tail -f "$newest"
        return 1
    fi
    exec tail -f "$today_log"
}

cli_runs() {
    local n="${1:-10}"
    local log_files
    log_files=$(ls -1t "$CURATOR_DIR"/log/2*.log 2>/dev/null | head -7)
    if [ -z "$log_files" ]; then
        echo "${C_DIM}no log files in $CURATOR_DIR/log/${C_OFF}"
        return 0
    fi
    printf "%-22s  %-10s  %-11s  %s\n" "RUN_ID" "OUTCOME" "CANDIDATES" "SOURCE LOG"
    printf "%-22s  %-10s  %-11s  %s\n" \
        "----------------------" "----------" "-----------" "----------"
    local f run_ids run_id outcome lines count short
    local count_shown=0
    for f in $log_files; do
        run_ids=$(grep -oE '\[[0-9]{8}-[0-9]{6}-[0-9]+\]' "$f" 2>/dev/null | sort -u -r)
        for run_id in $run_ids; do
            [ "$count_shown" -ge "$n" ] && break
            lines=$(grep -F "$run_id" "$f" 2>/dev/null || true)
            if echo "$lines" | grep -q "FAILED"; then
                outcome="FAIL"
            elif echo "$lines" | grep -q "curator run end (exit 0)"; then
                outcome="ok"
            else
                outcome="partial"
            fi
            count=$(echo "$lines" | grep -c "candidate: " 2>/dev/null || true)
            [ -z "$count" ] && count=0
            short=$(echo "$run_id" | tr -d '[]')
            printf "%-22s  %-10s  %-11s  %s\n" "$short" "$outcome" "$count" "$(basename "$f")"
            count_shown=$((count_shown + 1))
        done
        [ "$count_shown" -ge "$n" ] && break
    done
    if [ "$count_shown" -eq 0 ]; then
        echo "  ${C_DIM}(no runs recorded yet)${C_OFF}"
    fi
}

cli_help() {
    cat <<EOF
${C_BOLD}curator cli${C_OFF} — operator interface to the curator pipeline

Usage: bash tools/curator/cli.sh <verb> [args]

Verbs:
  ${C_BOLD}status${C_OFF}             One-pager: queue, runs, held, channel drafts
  ${C_BOLD}queue${C_OFF}              List all non-published candidates with their state
  ${C_BOLD}held${C_OFF}               List held candidates with reasons
  ${C_BOLD}retry${C_OFF} <id>         Reset held candidate → pending
  ${C_BOLD}tail${C_OFF}               Tail today's curator log (falls back to newest)
  ${C_BOLD}runs${C_OFF} [N]           Summarize last N runs (default 10)
  ${C_BOLD}audit${C_OFF}              Scan src/pages/ for future dates, [VERIFY], TODO/FIXME
                     (add --check-style for forbidden-phrase scan)
  ${C_BOLD}ui${C_OFF}                 Launch the local browser dashboard
                     (http://127.0.0.1:8088/; ctrl-c to stop)
  ${C_BOLD}help${C_OFF}               Show this message

Common workflows:
  Daily glance:           cli.sh status
  Something held:         cli.sh held → fix root cause → cli.sh retry <id>
  Reject a draft:         in cli.sh ui review modal — reject button
  Watch live run:         cli.sh tail

See ${C_DIM}tools/curator/OPERATING.md${C_OFF} for what-to-edit-where.
EOF
}

# ── Dispatch ───────────────────────────────────────────────────────────────

cli_audit() {
    exec python3 "$CURATOR_DIR/audit_site.py" "$@"
}

cli_ui() {
    exec python3 "$CURATOR_DIR/operator/server.py" "$@"
}

case "${1:-help}" in
    status)        shift; cli_status "$@" ;;
    queue)         shift; cli_queue "$@" ;;
    held)          shift; cli_held "$@" ;;
    retry)         shift; cli_retry "${1:-}" ;;
    tail)          shift; cli_tail "$@" ;;
    runs)          shift; cli_runs "${1:-10}" ;;
    audit)         shift; cli_audit "$@" ;;
    ui)            shift; cli_ui "$@" ;;
    help|--help|-h) cli_help ;;
    *)             echo "unknown verb: $1" >&2; echo ""; cli_help; exit 2 ;;
esac
