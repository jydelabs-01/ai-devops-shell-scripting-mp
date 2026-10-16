#!/bin/bash

# This is a script to capture the system health and performance metrics of a Linux system.
# It collects information about CPU usage, memory usage, disk usage, and network statistics, and saves the data to a log file for analysis.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MIN_AVAILABLE_MB=1000

# Print total and available memory in MB, separated by a space.
# Reads the "Mem:" line of free: total used free shared buff/cache available
get_memory_mb() {
    free -m | awk '/^Mem:/ {print $2, $7}'
}

# Write CPU, memory, disk and network metrics to a file: write_report <log_file>
write_report() {
    local log_file="$1"

    {
        echo "=== System Health Report: $(date) on $(hostname) ==="

        printf '\n%s\n' "--- CPU (load average: $(cut -d ' ' -f1-3 /proc/loadavg)) ---"
        top -b -n 1 | head -n 5
        printf '\n%s\n' "Top 10 processes by CPU usage:"
        ps aux --sort=-%cpu | head -n 11

        printf '\n%s\n' "--- Memory ---"
        free -m
        printf '\n%s\n' "Top 10 processes by memory usage:"
        ps aux --sort=-%mem | head -n 11

        printf '\n%s\n' "--- Disk ---"
        df -h -x tmpfs -x devtmpfs

        printf '\n%s\n' "--- Network ---"
        ip -brief address
        ss -s
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
    local log_file mem_total mem_available

    log_file="system_health_log_$(timestamp).txt"
    log_info "Starting system health monitoring..."

    read -r mem_total mem_available <<EOF
$(get_memory_mb)
EOF
    [ -n "$mem_available" ] || die "Could not read memory usage (is 'free' installed?)." 2

    write_report "$log_file"
    log_info "CPU, memory, disk and network metrics saved to $log_file."

    if check_memory "$mem_available" "$MIN_AVAILABLE_MB"; then
        log_info "Memory usage is within acceptable limits (${mem_available} MB available)."
    else
        log_warn "Memory is critically low (${mem_available} MB available of ${mem_total} MB)." 2>&1 | tee -a "$log_file"
        exit 1
    fi
}

main "$@"
