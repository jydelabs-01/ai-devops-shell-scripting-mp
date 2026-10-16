#!/bin/bash

# This is a script to capture the system health and performance metrics of a Linux system.
# It collects information about CPU usage, memory usage, disk usage, and network statistics, and saves the data to a log file for analysis.

MIN_AVAILABLE_MB=1000
log_file="system_health_log_$(date +%Y%m%d_%H%M%S).txt"

echo "Starting system health monitoring..."

# Read the "Mem:" line of free once: total used free shared buff/cache available
read -r mem_total mem_available <<EOF
$(free -m | awk '/^Mem:/ {print $2, $7}')
EOF

if [ -z "$mem_available" ]; then
    echo "ERROR: Could not read memory usage (is 'free' installed?)." >&2
    exit 2
fi

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

echo "CPU, memory, disk and network metrics saved to $log_file."

if [ "$mem_available" -lt "$MIN_AVAILABLE_MB" ]; then
    echo "WARNING: Memory is critically low (${mem_available} MB available of ${mem_total} MB)." | tee -a "$log_file"
    exit 1
fi
echo "Memory usage is within acceptable limits (${mem_available} MB available)."
