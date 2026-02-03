#!/bin/bash

# Video Metadata Timestamp Randomizer
# Randomizes all time-related metadata for video files in July 2025 between 16:03-20:27

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
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
        print_error "exiftool is not installed. Please install it first:"
        echo "  Ubuntu/Debian: sudo apt install libimage-exiftool-perl"
        echo "  CentOS/RHEL: sudo yum install perl-Image-ExifTool"
        echo "  Arch: sudo pacman -S perl-image-exiftool"
        exit 1
    fi
}

# Function to generate random timestamp in July 2025 between 16:03 and 20:27
generate_random_timestamp() {
    # July 2025 has 31 days
    local day=$((RANDOM % 31 + 1))
    
    # Time range: 16:03 (963 minutes from midnight) to 20:27 (1227 minutes from midnight)
    local min_minutes=963
    local max_minutes=1227
    local random_minutes=$((RANDOM % (max_minutes - min_minutes + 1) + min_minutes))
    
    local hour=$((random_minutes / 60))
    local minute=$((random_minutes % 60))
    local second=$((RANDOM % 60))
    
    # Format: YYYY:MM:DD HH:MM:SS
    printf "2025:07:%02d %02d:%02d:%02d" $day $hour $minute $second
}

# Function to generate random timecode for start_timecode
generate_random_timecode() {
    local day=$((RANDOM % 31 + 1))
    local min_minutes=963
    local max_minutes=1227
    local random_minutes=$((RANDOM % (max_minutes - min_minutes + 1) + min_minutes))
    
    local hour=$((random_minutes / 60))
    local minute=$((random_minutes % 60))
    local second=$((RANDOM % 60))
    local frame=$((RANDOM % 30)) # 30fps
    
    # Format: HH:MM:SS:FF
    printf "%02d:%02d:%02d:%02d" $hour $minute $second $frame
}

# Function to generate ISO format timestamp with timezone
generate_iso_timestamp() {
    local day=$((RANDOM % 31 + 1))
    local min_minutes=963
    local max_minutes=1227
    local random_minutes=$((RANDOM % (max_minutes - min_minutes + 1) + min_minutes))
    
    local hour=$((random_minutes / 60))
    local minute=$((random_minutes % 60))
    local second=$((RANDOM % 60))
    
    # Format: YYYY:MM:DD HH:MM:SS-04:00
    printf "2025:07:%02d %02d:%02d:%02d-04:00" $day $hour $minute $second
}

# Function to process a single video file
process_video_file() {
    local file="$1"
    local filename=$(basename "$file")
    
    print_status "Processing: $filename"
    
    # Generate random timestamps
    local datetime=$(generate_random_timestamp)
    local iso_datetime=$(generate_iso_timestamp)
    local timecode=$(generate_random_timecode)
    
    print_status "  Generated timestamp: $datetime"
    print_status "  Generated timecode: $timecode"
    
    # Create backup
    cp "$file" "${file}.backup"
    
    # Apply all timestamp modifications and remove AE project metadata using exiftool
    exiftool -overwrite_original \
        -TrackCreateDate="$datetime" \
        -TrackModifyDate="$datetime" \
        -MediaCreateDate="$datetime" \
        -MediaModifyDate="$datetime" \
        -CreateDate="$iso_datetime" \
        -ModifyDate="$iso_datetime" \
        -MetadataDate="$iso_datetime" \
        -StartTimecode="$timecode" \
        -StartTimecodeTimeValue="$timecode" \
        -AltTimecodeTimeValue="$timecode" \
        -HistoryWhen="$iso_datetime" \
        -CreationTime="$datetime" \
        -AEProjectLinkCompositionID= \
        -AEProjectLinkFullPath= \
        -AEProjectLinkRenderOutputModuleIndex= \
        -AEProjectLinkRenderQueueItemID= \
        "$file" 2>/dev/null
    
    if [ $? -eq 0 ]; then
        print_success "  Successfully processed: $filename"
        print_status "  Removed Adobe After Effects project metadata"
        # Also modify file system timestamps
        local fs_datetime=$(echo "$datetime" | sed 's/:/-/g' | sed 's/ /T/')
        touch -d "$fs_datetime" "$file" 2>/dev/null
    else
        print_error "  Failed to process: $filename"
        # Restore backup if exiftool failed
        mv "${file}.backup" "$file"
        return 1
    fi
    
    return 0
}

# Main function
main() {
    echo "================================================"
    echo "     Video Metadata Timestamp Randomizer"
    echo "================================================"
    echo ""
    
    # Check if exiftool is installed
    check_exiftool
    
    # Ask for directory path
    echo -n "Enter the path to the directory containing video files: "
    read -r video_dir
    
    # Validate directory
    if [ ! -d "$video_dir" ]; then
        print_error "Directory does not exist: $video_dir"
        exit 1
    fi
    
    # Find video files
    print_status "Searching for video files in: $video_dir"
    
    # Common video extensions
    video_files=()
    while IFS= read -r -d '' file; do
        video_files+=("$file")
    done < <(find "$video_dir" -maxdepth 1 -type f \( -iname "*.mp4" -o -iname "*.mov" -o -iname "*.avi" -o -iname "*.mkv" -o -iname "*.m4v" -o -iname "*.flv" -o -iname "*.wmv" \) -print0)
    
    if [ ${#video_files[@]} -eq 0 ]; then
        print_warning "No video files found in the specified directory."
        exit 0
    fi
    
    print_status "Found ${#video_files[@]} video file(s)"
    echo ""
    
    # List files to be processed
    echo "Files to be processed:"
    for file in "${video_files[@]}"; do
        echo "  - $(basename "$file")"
    done
    echo ""
    
    # Confirmation
    echo -n "Do you want to proceed? This will modify metadata and create backups (.backup extension). [y/N]: "
    read -r confirm
    
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        print_warning "Operation cancelled by user."
        exit 0
    fi
    
    echo ""
    print_status "Starting metadata randomization..."
    echo ""
    
    # Process each file
    local processed=0
    local failed=0
    
    for file in "${video_files[@]}"; do
        if process_video_file "$file"; then
            ((processed++))
        else
            ((failed++))
        fi
        echo ""
    done
    
    # Summary
    echo "================================================"
    echo "                   SUMMARY"
    echo "================================================"
    print_success "Successfully processed: $processed files"
    if [ $failed -gt 0 ]; then
        print_error "Failed to process: $failed files"
    fi
    echo ""
    print_status "Backup files created with .backup extension"
    print_status "All timestamps randomized to July 2025, 16:03-20:27"
    print_status "Adobe After Effects project metadata removed"
    echo ""
    
    # Cleanup confirmation
    if [ $failed -eq 0 ] && [ $processed -gt 0 ]; then
        echo -n "Do you want to remove backup files? [y/N]: "
        read -r cleanup
        if [[ "$cleanup" =~ ^[Yy]$ ]]; then
            for file in "${video_files[@]}"; do
                rm -f "${file}.backup"
            done
            print_success "Backup files removed."
        else
            print_status "Backup files preserved."
        fi
    fi
    
    echo ""
    print_success "Metadata randomization complete!"
}

# Run main function
main "$@"
