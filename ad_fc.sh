#!/bin/bash

# This is a script to create a directory and files within the directory.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/common.sh
source "$SCRIPT_DIR/lib/common.sh"

# Create a timestamped directory: create_directory <base_name>
# Prints the name of the directory it created.
create_directory() {
    local base_name="$1"
    local dir_name

    dir_name="${base_name}_$(timestamp)"
    mkdir -p "$dir_name" || return 1
    echo "$dir_name"
}

# Create one empty file inside a directory: create_file <directory> <file_name>
create_file() {
    local dir="$1"
    local file_name="$2"

    touch "$dir/$file_name" || return 1
    log_info "File '$file_name' has been created successfully."
}

# Ask for file names and create them: create_files <directory> <count>
create_files() {
    local dir="$1"
    local count="$2"
    local i file_name

    for ((i = 1; i <= count; i++)); do
        read -r -p "Enter the name of file $i: " file_name
        create_file "$dir" "$file_name" || return 1
    done
}

# Show the contents of a directory: show_directory <directory>
show_directory() {
    local dir="$1"

    log_info "Contents of '$dir':"
    ls -l "$dir"
}

main() {
    local base_name dir_name num_files

    read -r -p "Enter the name of the directory you want to create: " base_name
    dir_name=$(create_directory "$base_name") || die "Could not create directory '$base_name'."
    log_info "Directory '$dir_name' has been created successfully."

    read -r -p "Enter the number of files you want to create: " num_files
    is_positive_integer "$num_files" || die "'$num_files' is not a positive whole number."

    create_files "$dir_name" "$num_files" || die "Could not create files in '$dir_name'."
    show_directory "$dir_name"
}

main "$@"
