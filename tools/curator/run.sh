#!/bin/bash
# Curator orchestrator.
# Daily entrypoint. Reads new manifest entries from each lab and processes
# them through the pipeline. This Task 4 version is a scaffold: stages are
# placeholders that echo their name and exit clean. Real stage implementations
# arrive in subsequent tasks (T5 classifier, T6 drafting, T7 judges, etc).
#
# Usage:
#   bash tools/curator/run.sh           # full run
#   CURATOR_DEBUG=1 bash tools/curator/run.sh   # extra logging
#   bash tools/curator/run.sh --skip-ram-check  # bypass RAM precondition
#                                                  (testing only)

set -euo pipefail

# ── Setup ───────────────────────────────────────────────────────────────
CURATOR_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export CURATOR_DIR

. "$CURATOR_DIR/lib/log.sh"
. "$CURATOR_DIR/lib/ram_check.sh"

SKIP_RAM_CHECK=0
for arg in "$@"; do
    case "$arg" in
        --skip-ram-check) SKIP_RAM_CHECK=1 ;;
        *) log_warn "unknown arg: $arg" ;;
    esac
done

# Always log on exit so failures are visible.
on_exit() {
    local code=$?
    if [ "$code" -ne 0 ]; then
        log_error "curator run FAILED with exit code $code"
    else
        log_section "curator run end (exit 0)"
    fi
    exit "$code"
}
trap on_exit EXIT

# ── Stage 0: RAM precondition ───────────────────────────────────────────
log_section "stage 0: RAM precondition"
if [ "$SKIP_RAM_CHECK" -eq 0 ]; then
    if ! ram_check 12; then
        log_warn "RAM tight; deferring this run. Try again later or after labs idle."
        exit 0
    fi
else
    log_info "ram_check skipped (--skip-ram-check)"
fi

# ── Stage 1: scan manifests ─────────────────────────────────────────────
log_section "stage 1: scan manifests"
log_info "PLACEHOLDER (Task 5+): will scan ~/Desktop/Fun/lab/publish_candidates and ~/Desktop/AGI/data/publish_candidates for new entries."
NEW_CANDIDATES=()
log_info "found ${#NEW_CANDIDATES[@]} new candidates"

if [ "${#NEW_CANDIDATES[@]}" -eq 0 ]; then
    log_info "no new candidates → exit clean"
    exit 0
fi

# ── Stages 2+: per-candidate pipeline (placeholders) ────────────────────
for candidate in "${NEW_CANDIDATES[@]}"; do
    log_section "candidate: $candidate"
    log_info "stage 2 (classify):  PLACEHOLDER (Task 5)"
    log_info "stage 3 (draft):     PLACEHOLDER (Task 6)"
    log_info "stage 4 (judges):    PLACEHOLDER (Task 7)"
    log_info "stage 5 (validate):  PLACEHOLDER (Task 8)"
    log_info "stage 6 (provenance):PLACEHOLDER (Task 10)"
    log_info "stage 7 (publish):   PLACEHOLDER (Task 9)"
done

log_info "all candidates processed"
