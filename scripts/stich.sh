#!/bin/bash

# Function to get video resolution
get_resolution() {
  ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=p=0:s=x "$1"
}

# Function to calculate new video dimensions
calculate_new_dimensions() {
  local num_videos=$1
  local cols=$2
  local margin=$3

  local rows=$(( (num_videos + cols - 1) / cols ))
  local width=$(( video_width * cols + margin * (cols - 1) ))
  local height=$(( video_height * rows + margin * (rows - 1) ))

  echo "${width}x${height}"
}

# Ask if user wants to use all videos in a folder or specify each video path
echo "Do you want to use all videos in a folder (1) or enter paths of each video separately (2)?"
read -r option

video_paths=()

if [ "$option" -eq 1 ]; then
  echo "Enter the folder path:"
  read -r folder_path
  mapfile -t video_paths < <(find "$folder_path" -type f -name "*.mp4" | sort)
else
  echo "How many videos do you want to stitch?"
  read -r num_videos

  for (( i=1; i<=num_videos; i++ )); do
    echo "Enter the path for video $i:"
    read -r video_path
    video_paths+=("$video_path")
  done
fi

# Get resolution of the first video to calculate new dimensions
resolution=$(get_resolution "${video_paths[0]}")
video_width=$(echo "$resolution" | cut -d'x' -f1)
video_height=$(echo "$resolution" | cut -d'x' -f2)

# Ask how to stitch videos
echo "How do you want to stitch the videos?"
if [ "${#video_paths[@]}" -eq 2 ]; then
  echo "1) Vertically"
  echo "2) Horizontally"
  read -r layout
elif [ "${#video_paths[@]}" -eq 3 ]; then
  layout=3
elif [ "${#video_paths[@]}" -eq 4 ]; then
  layout=4
else
  echo "Enter the number of columns you want:"
  read -r columns
  layout="grid"
fi

# Ask for margin and background color
echo "Enter the margin between videos (in pixels):"
read -r margin

echo "Enter the background color (e.g., black, white, #RRGGBB):"
read -r bg_color

# Calculate new video size
if [ "$layout" == "grid" ]; then
  new_dimensions=$(calculate_new_dimensions "${#video_paths[@]}" "$columns" "$margin")
else
  if [ "$layout" == "1" ]; then
    columns=1
    rows=2
  elif [ "$layout" == "2" ]; then
    columns=2
    rows=1
  elif [ "$layout" == "3" ]; then
    columns=2
    rows=2
  elif [ "$layout" == "4" ]; then
    columns=2
    rows=2
  fi

  new_width=$(( video_width * columns + margin * (columns - 1) ))
  new_height=$(( video_height * rows + margin * (rows - 1) ))
  new_dimensions="${new_width}x${new_height}"
fi

echo "The new video size would be: $new_dimensions"

# Ask if user wants to scale down
echo "Do you want to scale the video down? (y/n)"
read -r scale_down

if [ "$scale_down" == "y" ]; then
  echo "Enter the new width (in pixels):"
  read -r new_width

  scale_factor=$(echo "scale=4; $new_width / $video_width" | bc)
  new_height=$(echo "scale=0; $video_height * $scale_factor / 1" | bc)
  new_dimensions="${new_width}x${new_height}"
  echo "The new scaled-down size is: $new_dimensions"
  echo "Is this okay? (y/n)"
  read -r is_ok

  if [ "$is_ok" != "y" ]; then
    echo "Enter the new width again:"
    read -r new_width

    scale_factor=$(echo "scale=4; $new_width / $video_width" | bc)
    new_height=$(echo "scale=0; $video_height * $scale_factor / 1" | bc)
    new_dimensions="${new_width}x${new_height}"
  fi
fi

# Ask for the output file name and folder
echo "Enter the output file name (without extension):"
read -r output_name

echo "Enter the output folder path:"
read -r output_folder

# Ensure the output folder path ends with a /
output_folder="${output_folder%/}/"

# Construct the FFmpeg filter for stitching
filter_complex=""
inputs=()

for (( i=0; i<${#video_paths[@]}; i++ )); do
  inputs+=("-i" "${video_paths[i]}")
done

# Add drawtext filters for each video
drawtext_filters=""
for (( i=0; i<${#video_paths[@]}; i++ )); do
  drawtext_filters+="[$i:v]drawtext=text='$(basename "${video_paths[i]}")':x=10:y=10:fontsize=24:fontcolor=white,format=yuv420p[v${i}]; "
done

# Construct layout filter
if [ "$layout" == "1" ]; then
  # Vertically
  filter_complex="${drawtext_filters}[0:v][1:v]vstack=inputs=2"
elif [ "$layout" == "2" ]; then
  # Horizontally
  filter_complex="${drawtext_filters}[0:v][1:v]hstack=inputs=2"
elif [ "$layout" == "3" ]; then
  # 3 videos (2 on top, 1 centered on bottom)
  filter_complex="${drawtext_filters}[0:v][1:v]hstack=inputs=2[top]; [2:v]pad=w=${video_width}:h=${video_height}:x=(ow-iw)/2:y=(oh-ih)/2[bottom]; [top][bottom]vstack=inputs=2"
elif [ "$layout" == "4" ]; then
  # 4 videos (2x2 grid)
  filter_complex="${drawtext_filters}[0:v][1:v]hstack=inputs=2[top]; [2:v][3:v]hstack=inputs=2[bottom]; [top][bottom]vstack=inputs=2"
else
  # Grid
  filter_complex="${drawtext_filters}"

  # Create the grid layout
  for (( i=0; i<${#video_paths[@]}; i++ )); do
    row=$((i / columns))
    col=$((i % columns))
    filter_complex+="[v${i}]pad=w=${video_width}:h=${video_height}:x=${col}*(${video_width}+${margin}):y=${row}*(${video_height}+${margin})[v${i}p]; "
  done

  filter_complex+="
  [0:v]pad=iw+${margin}:ih+${margin}:color=${bg_color}[background];
  [background]drawtext=text='$(basename "${video_paths[0]}")':x=10:y=10:fontsize=24:fontcolor=white"
fi

# Add padding to the final video
filter_complex="${filter_complex} [vfinal]pad=iw+${margin}:ih+${margin}:color=${bg_color}"

# Run FFmpeg to stitch the videos
ffmpeg "${inputs[@]}" -filter_complex "$filter_complex" \
  -c:v libx264 -crf 23 -preset veryfast "${output_folder}${output_name}.mp4"

echo "Video stitched and saved as ${output_folder}${output_name}.mp4"
