#!/bin/bash

# Function to get video resolution
get_resolution() {
    local file="$1"
    ffprobe -v error -select_streams v:0 -show_entries stream=width,height \
    -of csv=p=0:s=x "$file" 2>/dev/null
}

# Function to process videos in a directory
process_videos() {
    local dir="$1"
    echo "Processing directory: $dir"
    for file in "$dir"/*; do
        if [[ -f "$file" ]]; then
            local extension="${file##*.}"
            # Check if it's a video file based on extension
            if [[ "$extension" =~ ^(mp4|mkv|avi|mov|wmv|flv|webm|m4v|mpeg|ts)$ ]]; then
                local resolution
                resolution=$(get_resolution "$file")
                if [[ -n "$resolution" ]]; then
                    # Create folder for resolution if it doesn't exist
                    local folder="$dir/$resolution"
                    mkdir -p "$folder"
                    # Move the file into the folder
                    echo "Moving '$file' to '$folder/'"
                    mv "$file" "$folder/"
                else
                    echo "Could not determine resolution for: $file"
                fi
            fi
        fi
    done
}

# Default path
default_path="/media/tomas/Work/Library/Videos/"

# Parse arguments
path=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -l|--library)
            path="$default_path"
            shift
            ;;
        *)
            path="$1"
            shift
            ;;
    esac
done

# Check if path is provided
if [[ -z "$path" ]]; then
    read -rp "Enter the path to process: " path
fi

# Validate path
if [[ ! -d "$path" ]]; then
    echo "Error: Path '$path' does not exist or is not a directory."
    exit 1
fi

# Process each folder in the path (1 level deep)
for subdir in "$path"/*; do
    if [[ -d "$subdir" ]]; then
        process_videos "$subdir"
    fi
done

echo "Video organization complete."

