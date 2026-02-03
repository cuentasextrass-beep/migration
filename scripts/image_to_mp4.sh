#!/bin/bash

# Function to prompt for user input
prompt() {
    read -p "$1: " response
    echo "$response"
}

# Get the path to the image sequence
img_path=$(prompt "Enter the path to the image sequence")

# Get the name prefix of the files
file_prefix=$(prompt "Enter the name prefix of the image files")

# Get the number of digits in the sequence
num_digits=$(prompt "Enter the number of digits in the sequence numbers")

# Get the frame rate
frame_rate=$(prompt "Enter the frame rate (fps)")

# Ask if scaling is needed
scale_needed=$(prompt "Do you want to scale the resolution (yes/no)")

scale_factor=""
if [[ "$scale_needed" == "yes" ]]; then
    scale_factor=$(prompt "Enter the scale multiplier (e.g., 0.1, 0.5, 1.5, 2)")
    scale_factor="-vf scale=iw*$scale_factor:ih*$scale_factor"
fi

# Get the output path and filename
output_path=$(prompt "Enter the path where the output file should be saved")
output_name=$(prompt "Enter the name of the output file (without extension)")

# Create the output directory if it doesn't exist
if [[ ! -d "$output_path" ]]; then
    mkdir -p "$output_path"
    echo "Created directory: $output_path"
fi

# Build the output file path
output_file="$output_path/$output_name.mp4"

# Check if the output file already exists
if [[ -f "$output_file" ]]; then
    echo "The file $output_file already exists."
    output_name=$(prompt "Enter a new name for the output file (without extension)")
    output_file="$output_path/$output_name.mp4"
fi

# Build the input file pattern
input_file_pattern="$img_path/$file_prefix%0${num_digits}d.png"

# Run ffmpeg to convert the image sequence to MP4
ffmpeg -framerate "$frame_rate" -i "$input_file_pattern" -c:v libx264 -pix_fmt yuv420p $scale_factor "$output_file"

echo "Video created successfully at $output_file"
