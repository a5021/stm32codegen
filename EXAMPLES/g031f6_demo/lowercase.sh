#!/bin/bash

# Check if a filename was provided
if [ $# -eq 0 ]; then
    echo "Error: No filename provided"
    echo "Usage: $0 <filename>"
    exit 1
fi

original_name="$1"
lowercase_name=$(echo "$original_name" | tr '[:upper:]' '[:lower:]')

# Check if the filename actually needs changing
if [ "$original_name" = "$lowercase_name" ]; then
    echo "Filename is already lowercase: $original_name"
    exit 0
fi

# Rename the file
if [ -e "$original_name" ]; then
    mv -n "$original_name" "$lowercase_name"
    echo "Renamed: $original_name -> $lowercase_name"
else
    echo "Error: File '$original_name' does not exist"
    exit 1
fi
