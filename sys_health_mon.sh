#!/bin/bash

# This is a script to capture the system health and performance metrics of a Linux system.
# It collects information about CPU usage, memory usage, disk usage, and network statistics, and saves the data to a log file for analysis.
# Usage: ./sys_health_mon.sh [min_available_mb] [log_directory]

# -E: ERR trap also fires inside functions   -e: stop on the first failed command
# -u: treat unset variables as errors        -o pipefail: a pipeline fails if any part fails
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

DEFAULT_MIN_AVAILABLE_MB=1000

# Report is written here first and only moved to the real log name once complete,
# so an interrupted run never leaves a half-written log behind.
TMP_LOG=""

usage() {
    echo "Usage: $(basename "$0") [min_available_mb] [log_directory]"
    echo "Defaults: min_available_mb=$DEFAULT_MIN_AVAILABLE_MB, log_directory=."
}

# Delete the temporary report if the script stops before it is finished.
cleanup() {
    if [ -n "$TMP_LOG" ] && [ -e "$TMP_LOG" ]; then
        rm -f -- "$TMP_LOG"
    fi
}

# Keep a copy of the terminal's stderr on fd 3. write_report sends stderr into the
# log file, so the traps write to fd 3 to make sure their messages reach the user.
exec 3>&2

trap cleanup EXIT
trap 'on_error $? $LINENO "$BASH_COMMAND" 2>&3' ERR
trap 'die "Interrupted." 130 2>&3' INT TERM

# Print total and available memory in MB, separated by a space.
# Reads the "Mem:" line of free: total used free shared buff/cache available
get_memory_mb() {
    free -m | awk '/^Mem:/ {print $2, $7}'
}

# Write CPU, memory, disk and network metrics to a file: write_report <log_file>
# "|| true" keeps one failing command from stopping the whole report under set -e;
# on the "| head" lines it also covers head closing the pipe early, which pipefail
# would otherwise treat as a failure.
write_report() {
    local log_file="$1"

    {
        echo "=== System Health Report: $(date) on $(hostname) ==="

        printf '\n%s\n' "--- CPU (load average: $(cut -d ' ' -f1-3 /proc/loadavg)) ---"
        top -b -n 1 | head -n 5 || true
        printf '\n%s\n' "Top 10 processes by CPU usage:"
        ps aux --sort=-%cpu | head -n 11 || true

        printf '\n%s\n' "--- Memory ---"
        free -m || true
        printf '\n%s\n' "Top 10 processes by memory usage:"
        ps aux --sort=-%mem | head -n 11 || true

        printf '\n%s\n' "--- Disk ---"
        df -h -x tmpfs -x devtmpfs || true

        printf '\n%s\n' "--- Network ---"
        ip -brief address || true
        ss -s || true
    } > "$log_file" 2>&1
}

# Check available memory against a threshold: check_memory <available_mb> <threshold_mb>
# Returns 0 if there is enough memory, 1 if it is below the threshold.
check_memory() {
    local available="$1"
    local threshold="$2"

    [ "$available" -ge "$threshold" ]
}

main() {
    local min_available_mb log_dir log_file mem_total mem_available

    case "${1:-}" in
        -h | --help)
            usage
            exit 0
            ;;
    esac
    [ "$#" -le 2 ] || { usage >&2; die "Too many arguments."; }

    min_available_mb="${1:-$DEFAULT_MIN_AVAILABLE_MB}"
    log_dir="${2:-.}"
    is_positive_integer "$min_available_mb" || die "'$min_available_mb' is not a positive whole number of MB."
    require_writable_dir "$log_dir"
    require_commands free ps df top ip ss

    log_file="${log_dir%/}/system_health_log_$(timestamp).txt"
    log_info "Starting system health monitoring..."

    read -r mem_total mem_available <<EOF
$(get_memory_mb)
EOF
    if ! is_positive_integer "$mem_total" || ! is_positive_integer "$mem_available"; then
        die "Could not read memory usage from 'free'." 2
    fi

    TMP_LOG=$(mktemp "${log_dir%/}/.system_health_log.XXXXXX")
    write_report "$TMP_LOG"
    mv -- "$TMP_LOG" "$log_file"
    TMP_LOG=""
    log_info "CPU, memory, disk and network metrics saved to $log_file."

    if check_memory "$mem_available" "$min_available_mb"; then
        log_info "Memory usage is within acceptable limits (${mem_available} MB available)."
    else
        log_warn "Memory is critically low (${mem_available} MB available of ${mem_total} MB)." 2>&1 | tee -a "$log_file"
        exit 1
    fi
}

main "$@"
