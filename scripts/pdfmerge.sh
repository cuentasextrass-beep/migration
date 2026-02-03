#!/bin/bash

# Function to normalize the directory path (ensure no trailing slash)
normalize_dir() {
    echo "$1" | sed 's:/*$::'
}

# Ask for the first PDF file
read -p "Enter the path of the first PDF: " pdf1

# Ask for the second PDF file
read -p "Enter the path of the second PDF: " pdf2

# Ask for the output directory and file name
read -p "Enter the output directory: " output_dir
read -p "Enter the name of the output PDF (e.g., merged.pdf): " output_pdf

# Normalize the output directory to ensure no trailing slash
output_dir=$(normalize_dir "$output_dir")

# Create the output path
output_path="$output_dir/$output_pdf"

# Extract the first page of both PDFs
pdftk "$pdf1" cat 1 output first_page1.pdf
pdftk "$pdf2" cat 1 output first_page2.pdf

# Merge the two extracted pages into one PDF
pdftk first_page1.pdf first_page2.pdf cat output "$output_path"

# Clean up the intermediate files
rm first_page1.pdf first_page2.pdf

echo "Merged PDF created at: $output_path"
