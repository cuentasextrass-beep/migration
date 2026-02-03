#!/bin/bash

# Script to remove metadata from all files in a directory recursively
# Creates a backup before processing

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if exiftool is installed
check_exiftool() {
    if ! command -v exiftool &> /dev/null; then
        print_error "exiftool is not installed!"
        print_info "Please install it with: sudo apt update && sudo apt install exiftool"
        exit 1
    fi
}

# Function to validate path
validate_path() {
    local path="$1"
    
    if [[ ! -d "$path" ]]; then
        print_error "Directory '$path' does not exist!"
        return 1
    fi
    
    if [[ ! -r "$path" ]]; then
        print_error "Directory '$path' is not readable!"
        return 1
    fi
    
    if [[ ! -w "$path" ]]; then
        print_error "Directory '$path' is not writable!"
        return 1
    fi
    
    return 0
}

# Function to create backup
create_backup() {
    local source_path="$1"
    local backup_path="$2"
    
    print_info "Creating backup: $backup_path"
    
    if [[ -e "$backup_path" ]]; then
        print_warning "Backup already exists: $backup_path"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled."
            exit 0
        fi
        rm -rf "$backup_path"
    fi
    
    # Use rsync for better handling of permissions and symlinks
    if command -v rsync &> /dev/null; then
        rsync -av --progress "$source_path/" "$backup_path/"
    else
        cp -r "$source_path" "$backup_path"
    fi
    
    print_success "Backup created successfully!"
}

# Function to remove metadata
remove_metadata() {
    local target_path="$1"
    
    print_info "Starting metadata removal process..."
    print_warning "This will permanently remove metadata from all files in: $target_path"
    
    # Count total files for progress indication
    local total_files=$(find "$target_path" -type f | wc -l)
    print_info "Found $total_files files to process"
    
    if [[ $total_files -eq 0 ]]; then
        print_warning "No files found to process!"
        return 0
    fi
    
    # Ask for final confirmation
    read -p "Are you sure you want to proceed? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled."
        return 0
    fi
    
    print_info "Removing metadata from all files (this may take a while)..."
    
    # Use exiftool to remove all metadata recursively
    # -all= removes all metadata
    # -r processes recursively
    # -overwrite_original modifies files in place
    # -progress shows progress
    exiftool -all= -r -overwrite_original -progress "$target_path"
    
    local exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        print_success "Metadata removal completed successfully!"
        
        # Clean up any .exiftool_tmp files that might be left behind
        find "$target_path" -name "*.exiftool_tmp" -type f -delete 2>/dev/null || true
        
        print_info "Removed any temporary files created during processing"
    else
        print_error "Some errors occurred during metadata removal (exit code: $exit_code)"
        print_info "Check the output above for details"
        return $exit_code
    fi
}

# Function to show disk usage comparison
show_disk_usage() {
    local original_path="$1"
    local backup_path="$2"
    
    if [[ -d "$backup_path" && -d "$original_path" ]]; then
        print_info "Disk usage comparison:"
        local backup_size=$(du -sh "$backup_path" | cut -f1)
        local original_size=$(du -sh "$original_path" | cut -f1)
        echo "  Backup:   $backup_size ($backup_path)"
        echo "  Original: $original_size ($original_path)"
    fi
}

# Main function
main() {
    echo "=============================================="
    echo "    Metadata Removal Script for Linux"
    echo "=============================================="
    echo
    
    # Check dependencies
    check_exiftool
    
    # Get path from user
    while true; do
        read -p "Enter the path to process: " input_path
        
        # Handle empty input
        if [[ -z "$input_path" ]]; then
            print_error "Please enter a valid path!"
            continue
        fi
        
        # Expand tilde and resolve path
        input_path="${input_path/#\~/$HOME}"
        input_path=$(realpath "$input_path" 2>/dev/null) || {
            print_error "Invalid path format!"
            continue
        }
        
        # Validate path
        if validate_path "$input_path"; then
            break
        fi
    done
    
    # Create backup path
    local dir_name=$(basename "$input_path")
    local parent_dir=$(dirname "$input_path")
    local backup_path="${parent_dir}/${dir_name}_backup"
    
    print_info "Source path: $input_path"
    print_info "Backup path: $backup_path"
    echo
    
    # Show what will happen
    print_warning "This script will:"
    echo "  1. Create a complete backup of your directory"
    echo "  2. Remove ALL metadata from ALL files in the original directory"
    echo "  3. Process files recursively (including subdirectories)"
    echo
    print_warning "Metadata includes: EXIF data, GPS coordinates, camera info, creation dates, etc."
    echo
    
    # Final confirmation
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled."
        exit 0
    fi
    
    # Create backup
    create_backup "$input_path" "$backup_path"
    
    # Remove metadata from original
    remove_metadata "$input_path"
    
    # Show results
    echo
    print_success "Process completed!"
    show_disk_usage "$input_path" "$backup_path"
    
    echo
    print_info "Summary:"
    echo "  ✓ Backup created at: $backup_path"
    echo "  ✓ Metadata removed from: $input_path"
    echo "  ✓ Original files preserved in backup"
}

# Handle Ctrl+C gracefully
trap 'echo; print_info "Operation cancelled by user."; exit 130' INT

# Run main function
main "$@"