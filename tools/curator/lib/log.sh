#!/bin/bash
# Logging helpers for the curator pipeline.
# Source this file: . tools/curator/lib/log.sh
# Sets CURATOR_LOG to today's log file path.

# Always resolve CURATOR_DIR from this script's own location, overriding any
# stale env value. This is robust against shells where a parent script set
# CURATOR_DIR to something unrelated.
CURATOR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
export CURATOR_DIR

CURATOR_LOG_DIR="${CURATOR_DIR}/log"
mkdir -p "$CURATOR_LOG_DIR"

# One log file per day. Curator runs at most ~once per day; if multiple runs
# happen, they append to the same file (handy for debugging).
CURATOR_LOG="${CURATOR_LOG_DIR}/$(date +%Y-%m-%d).log"

# Run ID for cross-line correlation.
CURATOR_RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"

_log() {
    local level="$1"
    shift
    local msg="$*"
    local ts
    ts="$(date +%Y-%m-%dT%H:%M:%S%z)"
    local line="${ts} [${CURATOR_RUN_ID}] [${level}] ${msg}"
    # Write to log file always; write to stderr so callers using
    # $(...) capture don't get log lines mixed into their returns.
    echo "$line" >> "$CURATOR_LOG"
    echo "$line" >&2
}

log_info() { _log "INFO" "$@"; }
log_warn() { _log "WARN" "$@"; }
log_error() { _log "ERROR" "$@"; }
log_debug() {
    # Debug logs only emit when CURATOR_DEBUG=1
    [ "${CURATOR_DEBUG:-0}" = "1" ] && _log "DEBUG" "$@"
}

# Print a section break to make logs readable.
log_section() {
    local title="$1"
    _log "INFO" "── ${title} ──────────────────────────────"
}

# Emit run header on first source.
if [ "${CURATOR_LOG_HEADER_EMITTED:-}" != "1" ]; then
    export CURATOR_LOG_HEADER_EMITTED=1
    log_section "curator run start"
    log_info "run_id=${CURATOR_RUN_ID} pid=$$ host=$(hostname -s)"
fi
