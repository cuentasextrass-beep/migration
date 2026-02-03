#!/bin/bash

# Function to prompt for user input
prompt() {
    read -p "$1: " response
    echo "$response"
}

# Get the path to the video file
video_path=$(prompt "Enter the path to the video file")

# Get the output image format
output_format=$(prompt "Enter the output image format (jpg, png, exr)")

# Get the output path
output_path=$(prompt "Enter the path where the image sequence should be saved")

# Create the output directory if it doesn't exist
if [[ ! -d "$output_path" ]]; then
    mkdir -p "$output_path"
    echo "Created directory: $output_path"
fi

# Get the name prefix for the output image files
file_prefix=$(prompt "Enter the name prefix for the output image files")

# Get the number of digits in the sequence
num_digits=$(prompt "Enter the number of digits in the sequence numbers")

# Ask if scaling is needed
scale_needed=$(prompt "Do you want to scale the resolution (yes/no)")

scale_filter=""
if [[ "$scale_needed" == "yes" ]]; then
    scale_factor=$(prompt "Enter the scale multiplier (e.g., 0.1, 0.5, 1.5, 2)")
    scale_filter=",scale=iw*$scale_factor:ih*$scale_factor"
fi

# Get the frame rate from the video file
frame_rate=$(ffmpeg -i "$video_path" 2>&1 | sed -n "s/.*, \(.*\) fps.*/\1/p")

# Build the output file pattern
output_file_pattern="$output_path/${file_prefix}_%0${num_digits}d.$output_format"

# Run ffmpeg to convert the video to an image sequence
ffmpeg -i "$video_path" -vf "fps=$frame_rate$scale_filter" "$output_file_pattern"

echo "Image sequence created successfully at $output_path"

