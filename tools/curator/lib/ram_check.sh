#!/bin/bash
# RAM precondition check for the curator.
# Sources lib/log.sh if not already loaded.
#
# Usage:
#   . tools/curator/lib/ram_check.sh
#   ram_check 12   # require at least 12 GB free; returns nonzero if not
#
# Implementation notes:
# - macOS vm_stat reports memory in 4KB pages.
# - "Free" pages alone are misleading on macOS because the OS aggressively
#   uses memory for cache/inactive. The right "available for new allocations"
#   approximation is: free + inactive + speculative.
# - For the curator's use case, peak ~9GB during 14B inference. Default
#   threshold of 12GB gives ~3GB margin for OS + IO buffers.

[ -z "${CURATOR_LOG:-}" ] && {
    SELF_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    . "$SELF_DIR/log.sh"
}

# Get available RAM in GB (rounded down). Returns integer.
ram_available_gb() {
    # Extract actual page size from vm_stat header. M-series Macs use 16KB
    # pages, Intel Macs use 4KB. Hardcoding either is a bug.
    local pagesize
    pagesize=$(vm_stat | head -1 | grep -oE '[0-9]+' | head -1)
    if [ -z "$pagesize" ] || [ "$pagesize" -lt 4096 ]; then
        pagesize=16384  # Apple Silicon default if parse fails
    fi
    local pages
    pages=$(vm_stat | awk '
        /^Pages free:/ {free=$3+0}
        /^Pages inactive:/ {inactive=$3+0}
        /^Pages speculative:/ {spec=$3+0}
        END {print free + inactive + spec}
    ' | tr -d '.')
    # bytes = pages * pagesize; GB = bytes / 1024^3
    local gb=$(( pages * pagesize / 1024 / 1024 / 1024 ))
    echo "$gb"
}

# Returns 0 (success) if enough RAM free; 1 otherwise.
# Logs the result either way.
ram_check() {
    local required="${1:-12}"
    local actual
    actual=$(ram_available_gb)

    if [ "$actual" -ge "$required" ]; then
        log_info "ram_check: ${actual} GB free, required ${required} GB → OK"
        return 0
    else
        log_warn "ram_check: ${actual} GB free, required ${required} GB → DEFER"
        return 1
    fi
}
