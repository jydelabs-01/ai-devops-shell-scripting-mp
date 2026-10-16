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

# Report which command failed when set -e stops a script.
# Use with: trap 'on_error $? $LINENO "$BASH_COMMAND"' ERR
on_error() {
    local exit_code="$1"
    local line="$2"
    local command="$3"

    log_error "Line $line: '$command' failed with exit code $exit_code."
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

# Return 0 if $1 is a safe file or directory name, 1 otherwise.
# Allowed: letters, digits, '.', '_' and '-', up to 100 characters.
# Rejected: empty names, slashes, spaces, and names starting with '-' or '.'.
is_valid_name() {
    local name="$1"

    case "$name" in
        '' | -* | .* | *[!A-Za-z0-9._-]*) return 1 ;;
    esac
    [ "${#name}" -le 100 ]
}

# Exit with an error unless $1 is an existing, writable directory: require_writable_dir <path>
require_writable_dir() {
    local dir="$1"

    [ -e "$dir" ] || die "'$dir' does not exist."
    [ -d "$dir" ] || die "'$dir' is not a directory."
    [ -w "$dir" ] || die "'$dir' is not writable."
}

# Exit with code 2 unless every named command is installed: require_commands <command>...
require_commands() {
    local cmd
    local missing=""

    for cmd in "$@"; do
        command -v "$cmd" > /dev/null 2>&1 || missing="$missing $cmd"
    done
    [ -z "$missing" ] || die "Missing required commands:$missing" 2
}
