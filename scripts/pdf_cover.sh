#!/bin/bash

# Ask for the input and output folders
read -p "Enter the path to the folder containing PDFs: " pdf_folder
read -p "Enter the path to save the images: " output_folder

# Check if the input folder exists
if [ ! -d "$pdf_folder" ]; then
  echo "The folder '$pdf_folder' does not exist. Exiting."
  exit 1
fi

# Create the output folder if it doesn't exist
if [ ! -d "$output_folder" ]; then
  mkdir -p "$output_folder"
  echo "Created output folder: $output_folder"
fi

# Loop through all PDF files in the input folder
for pdf_file in "$pdf_folder"/*.pdf; do
  # Check if the file exists
  if [ -f "$pdf_file" ]; then
    # Extract the first page as a PNG image using pdfimages
    base_name=$(basename "$pdf_file" .pdf)
    image_path="$output_folder/${base_name}.png"
    
    # Extract the first page and convert it to PNG
    pdftoppm -png -f 1 -l 1 "$pdf_file" "$output_folder/$base_name"

    # Rename the output from .png-1.png to .png
    mv "$output_folder/${base_name}-1.png" "$image_path"

    echo "Saved: $image_path"
  fi
done

echo "All PDF first pages have been converted and saved as images."

