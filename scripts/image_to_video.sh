#!/bin/bash

# Function to prompt for user input
prompt() {
    read -p "$1: " response
    echo "$response"
}

# Function to detect image sequences in the given directory
detect_sequences() {
    local path=$1
    declare -A sequences

    for file in "$path"/*; do
        if [[ -f "$file" ]]; then
            base=$(basename "$file")
            prefix="${base%%[0-9]*}"
            suffix="${base##*.}"
            if [[ "$prefix" && "$suffix" ]]; then
                sequences["$prefix.$suffix"]=1
            fi
        fi
    done

    echo "${!sequences[@]}"
}

# Get the path to the image sequence
img_path=$(prompt "Enter the path to the image sequence")

# Detect available sequences
sequences=$(detect_sequences "$img_path")
IFS=' ' read -r -a sequences_array <<< "$sequences"

if [[ ${#sequences_array[@]} -eq 0 ]]; then
    echo "No image sequences found in the specified directory."
    exit 1
elif [[ ${#sequences_array[@]} -eq 1 ]]; then
    sequence="${sequences_array[0]}"
else
    echo "Multiple image sequences found:"
    for i in "${!sequences_array[@]}"; do
        echo "$((i + 1)). ${sequences_array[$i]}"
    done
    choice=$(prompt "Enter the number of the sequence to use")
    sequence="${sequences_array[$((choice - 1))]}"
fi

echo "Chosen sequence: $sequence"

# Parse the chosen sequence
file_prefix="${sequence%.*}"
file_extension="${sequence##*.}"

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

# Ask for the output format
output_format=$(prompt "Enter the output format (mp4, mov, gif)")

# List recommended codecs based on the format
case "$output_format" in
    mp4)
        echo "Recommended codecs for mp4: 1) libx264, 2) libx265"
        codec_choice=$(prompt "Enter the number of the codec to use")
        case $codec_choice in
            1) codec="libx264";;
            2) codec="libx265";;
            *) echo "Invalid choice. Exiting."; exit 1;;
        esac
        ;;
    mov)
        echo "Recommended codecs for mov: 1) libx264, 2) prores_ks"
        codec_choice=$(prompt "Enter the number of the codec to use")
        case $codec_choice in
            1) codec="libx264";;
            2) codec="prores_ks";;
            *) echo "Invalid choice. Exiting."; exit 1;;
        esac
        ;;
    gif)
        echo "Recommended codec for gif: gif"
        codec="gif"
        ;;
    *)
        echo "Unsupported format. Exiting."
        exit 1
        ;;
esac

# Get the output path and filename
output_path=$(prompt "Enter the path where the output file should be saved")
output_name=$(prompt "Enter the name of the output file (without extension)")

# Create the output directory if it doesn't exist
if [[ ! -d "$output_path" ]]; then
    mkdir -p "$output_path"
    echo "Created directory: $output_path"
fi

# Build the output file path
output_file="$output_path/$output_name.$output_format"

# Check if the output file already exists
if [[ -f "$output_file" ]]; then
    echo "The file $output_file already exists."
    output_name=$(prompt "Enter a new name for the output file (without extension)")
    output_file="$output_path/$output_name.$output_format"
fi

# Build the input file pattern
input_file_pattern="$img_path/$file_prefix%0${num_digits}d.$file_extension"

# Print the detected sequences and the ffmpeg command for debugging
echo "Detected sequences: ${sequences_array[*]}"
echo "Input file pattern: $input_file_pattern"
echo "ffmpeg command: ffmpeg -framerate \"$frame_rate\" -i \"$input_file_pattern\" -c:v \"$codec\" -pix_fmt yuv420p $scale_factor \"$output_file\""

# Run ffmpeg to convert the image sequence
ffmpeg -framerate "$frame_rate" -i "$input_file_pattern" -c:v "$codec" -pix_fmt yuv420p $scale_factor "$output_file"

echo "Video created successfully at $output_file"

