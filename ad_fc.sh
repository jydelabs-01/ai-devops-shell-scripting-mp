#!/bin/bash

# This is a script to create a directory and files within the directory.
# Usage: ./ad_fc.sh [parent_directory]    (defaults to the current directory)

# -E: ERR trap also fires inside functions   -e: stop on the first failed command
# -u: treat unset variables as errors        -o pipefail: a pipeline fails if any part fails
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

MAX_FILES=100

# Directory created by this run; the cleanup trap removes it if the script fails.
CREATED_DIR=""

usage() {
    echo "Usage: $(basename "$0") [parent_directory]"
    echo "Creates a timestamped directory inside parent_directory (default: .) and files within it."
}

# Remove the directory this run created if the script did not finish successfully.
cleanup() {
    local exit_code=$?

    if [ "$exit_code" -ne 0 ] && [ -n "$CREATED_DIR" ] && [ -d "$CREATED_DIR" ]; then
        rm -rf -- "$CREATED_DIR"
        log_warn "Removed incomplete directory '$CREATED_DIR'."
    fi
}

trap cleanup EXIT
trap 'on_error $? $LINENO "$BASH_COMMAND"' ERR
trap 'die "Interrupted." 130' INT TERM

# Create a new directory and remember it for cleanup: create_directory <path>
# Uses mkdir without -p so it fails if the path already exists; the cleanup
# trap must only ever delete a directory this run created.
create_directory() {
    local dir_path="$1"

    mkdir -- "$dir_path" || return 1
    CREATED_DIR="$dir_path"
}

# Create one empty file inside a directory: create_file <directory> <file_name>
create_file() {
    local dir="$1"
    local file_name="$2"

    touch -- "$dir/$file_name" || return 1
    log_info "File '$file_name' has been created successfully."
}

# Ask for file names and create them: create_files <directory> <count>
# Keeps asking until each name is valid and not already used.
create_files() {
    local dir="$1"
    local count="$2"
    local i file_name

    for ((i = 1; i <= count; i++)); do
        while true; do
            read -r -p "Enter the name of file $i: " file_name || die "No input received."
            if ! is_valid_name "$file_name"; then
                log_warn "'$file_name' is not a valid name (use letters, digits, '.', '_' or '-')."
            elif [ -e "$dir/$file_name" ]; then
                log_warn "'$file_name' already exists in '$dir'."
            else
                break
            fi
        done
        create_file "$dir" "$file_name"
    done
}

# Show the contents of a directory: show_directory <directory>
show_directory() {
    local dir="$1"

    log_info "Contents of '$dir':"
    ls -l -- "$dir"
}

main() {
    local parent_dir base_name dir_path num_files

    case "${1:-}" in
        -h | --help)
            usage
            exit 0
            ;;
    esac
    [ "$#" -le 1 ] || { usage >&2; die "Too many arguments."; }

    parent_dir="${1:-.}"
    require_writable_dir "$parent_dir"

    # Validate every answer before changing anything on disk.
    read -r -p "Enter the name of the directory you want to create: " base_name || die "No input received."
    is_valid_name "$base_name" || die "'$base_name' is not a valid name (use letters, digits, '.', '_' or '-')."

    read -r -p "Enter the number of files you want to create (1-$MAX_FILES): " num_files || die "No input received."
    is_positive_integer "$num_files" || die "'$num_files' is not a positive whole number."
    [ "$num_files" -le "$MAX_FILES" ] || die "Refusing to create more than $MAX_FILES files."

    dir_path="${parent_dir%/}/${base_name}_$(timestamp)"
    create_directory "$dir_path" || die "Could not create directory '$dir_path'."
    log_info "Directory '$dir_path' has been created successfully."

    create_files "$dir_path" "$num_files"
    show_directory "$dir_path"
}

main "$@"
