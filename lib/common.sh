#!/bin/bash

# Shared helper functions for the scripts in this project.
# Load it with: source "$SCRIPT_DIR/lib/common.sh" (do not run it directly).

# Print an informational message: log_info <message>
log_info() {
    echo "[INFO]  $1"
}

# Print a warning to stderr: log_warn <message>
log_warn() {
    echo "[WARN]  $1" >&2
}

# Print an error to stderr: log_error <message>
log_error() {
    echo "[ERROR] $1" >&2
}

# Print an error and exit: die <message> [exit_code]
# The exit code defaults to 1 when $2 is not given.
die() {
    local message="$1"
    local exit_code="${2:-1}"

    log_error "$message"
    exit "$exit_code"
}

# Print a timestamp for file and directory names, e.g. 20261016_214500
timestamp() {
    date +%Y%m%d_%H%M%S
}

# Return 0 if $1 is a whole number greater than zero, 1 otherwise.
is_positive_integer() {
    local value="$1"

    case "$value" in
        '' | *[!0-9]*) return 1 ;;
    esac
    [ "$value" -gt 0 ]
}
