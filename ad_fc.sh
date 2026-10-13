#!/bin/bash

#This is a script to create directories and files within the directories
#first create a directory

echo "Creating directory 'my_directory'..." 
read -p "Enter the name of the directory you want to create: " my_directory
mkdir -p "$my_directory"
echo "Directory '$my_directory' has been created successfully."

##Next create files within the directory
echo "Creating files within the directory '$my_directory'."
cd "$my_directory" || exit 1
read -p "Enter the number of files you want to create: " num_files
for ((i=1; i<=$num_files; i++))
do 
    read -p "Enter the name of the file $i: " file_name
    touch "$file_name"
    echo "File $file_name has been created successfully."
done
echo "validate and display the contents of the directory '$my_directory'."

ls -l




