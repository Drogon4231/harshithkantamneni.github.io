#!/bin/bash
# Logging helpers for the curator pipeline.
# Source this file: . tools/curator/lib/log.sh
# Sets CURATOR_LOG to today's log file path.

# Caller may set CURATOR_DIR; default is the dir containing this script's parent.
: "${CURATOR_DIR:=$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )}"

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
    echo "${ts} [${CURATOR_RUN_ID}] [${level}] ${msg}" | tee -a "$CURATOR_LOG"
}

log_info() { _log "INFO" "$@"; }
log_warn() { _log "WARN" "$@"; }
log_error() { _log "ERROR" "$@" 1>&2; }
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
