#!/bin/bash

# ComfyUI Installation Script
# This script installs ComfyUI, ComfyUI Manager, and sets up the launcher

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_message() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}!${NC} $1"
}

# Check if running from home directory or navigate to it
cd ~

print_message "Starting ComfyUI installation..."
echo ""

# Step 1: Clone ComfyUI repository
print_message "Step 1: Cloning ComfyUI repository..."
if [ -d "ComfyUI" ]; then
    print_warning "ComfyUI directory already exists. Skipping clone."
else
    git clone https://github.com/Comfy-Org/ComfyUI.git
    print_success "ComfyUI cloned successfully"
fi
echo ""

# Step 2: Clone ComfyUI Manager
print_message "Step 2: Installing ComfyUI Manager..."
cd ComfyUI/custom_nodes
if [ -d "ComfyUI-Manager" ]; then
    print_warning "ComfyUI-Manager already exists. Skipping clone."
else
    git clone https://github.com/Comfy-Org/ComfyUI-Manager.git
    print_success "ComfyUI Manager installed successfully"
fi
echo ""

# Step 3: Install system dependencies
print_message "Step 3: Installing system dependencies (python3, venv, pip)..."
sudo apt update
sudo apt install -y python3 python3-venv python3-pip
print_success "System dependencies installed"
echo ""

# Step 4: Navigate to ComfyUI directory
cd ~/ComfyUI

# Step 5: Create virtual environment
print_message "Step 4: Creating Python virtual environment..."
if [ -d ".venv" ]; then
    print_warning "Virtual environment already exists. Skipping creation."
else
    python3 -m venv .venv
    print_success "Virtual environment created"
fi
echo ""

# Step 6: Activate virtual environment and install requirements
print_message "Step 5: Activating virtual environment and installing requirements..."
source .venv/bin/activate

print_message "Upgrading pip..."
pip install --upgrade pip
print_success "pip upgraded"
echo ""

print_message "Installing ComfyUI requirements (this may take a few minutes)..."
pip install -r requirements.txt
print_success "Requirements installed successfully"
echo ""

# Step 7: Create the launcher script
print_message "Step 6: Creating ComfyUI launcher script..."
cat > ~/ComfyUI/comfy_launcher.sh << 'LAUNCHER_EOF'
#!/bin/bash

# ComfyUI Launcher - Wrapper Script
# This wrapper ensures the original terminal closes properly

# Color definitions
ORANGE_BG="#2d1f0d"
ORANGE_FG="#ffb366"

# Detect available terminal emulator
detect_terminal() {
    if command -v gnome-terminal &> /dev/null; then
        echo "gnome-terminal"
    elif command -v konsole &> /dev/null; then
        echo "konsole"
    elif command -v xterm &> /dev/null; then
        echo "xterm"
    elif command -v xfce4-terminal &> /dev/null; then
        echo "xfce4-terminal"
    else
        echo "none"
    fi
}

TERMINAL=$(detect_terminal)

if [ "$TERMINAL" = "none" ]; then
    echo "Error: No compatible terminal emulator found!"
    echo "Please install gnome-terminal, konsole, xterm, or xfce4-terminal"
    exit 1
fi

# Create the main launcher script
cat > /tmp/comfyui_main_launcher.sh << 'MAIN_EOF'
#!/bin/bash

# Color definitions
ORANGE_BG="#2d1f0d"
ORANGE_FG="#ffb366"
GREEN_BG="#162c22"
GREEN_FG="#00ff00"

# Detect terminal
detect_terminal() {
    if command -v gnome-terminal &> /dev/null; then
        echo "gnome-terminal"
    elif command -v konsole &> /dev/null; then
        echo "konsole"
    elif command -v xterm &> /dev/null; then
        echo "xterm"
    elif command -v xfce4-terminal &> /dev/null; then
        echo "xfce4-terminal"
    else
        echo "none"
    fi
}

TERMINAL=$(detect_terminal)

# Create the monitoring terminal script
cat > /tmp/gpu_monitor.sh << 'MONITOR_EOF'
#!/bin/bash

# Kill any existing session
tmux kill-session -t gpu-monitor 2>/dev/null

# Get current terminal size
current_rows=$(tput lines)
current_cols=$(tput cols)

# Double the height
new_rows=$((current_rows * 2))

# Create new tmux session
tmux new-session -d -s gpu-monitor -x "$current_cols" -y "$new_rows"

# Set dark green background color for tmux
tmux set-option -t gpu-monitor status-style bg=colour22,fg=colour46
tmux set-option -t gpu-monitor pane-active-border-style fg=colour46
tmux set-option -t gpu-monitor pane-border-style fg=colour22

# Set dark green background for the terminal content
tmux send-keys -t gpu-monitor "printf '\e]11;#162c22\007'" C-m
tmux send-keys -t gpu-monitor "export PS1='\[\e[48;5;22m\e[38;5;46m\]\u@\h:\w\$ \[\e[0m\]'" C-m
tmux send-keys -t gpu-monitor clear C-m

# Split window horizontally (top/bottom)
tmux split-window -t gpu-monitor -v

# Select top pane and run nvidia-smi watch
tmux select-pane -t gpu-monitor:0.0
tmux send-keys -t gpu-monitor:0.0 "printf '\e]11;#162c22\007'" C-m
tmux send-keys -t gpu-monitor:0.0 "watch -n 0.5 --color 'nvidia-smi'" C-m

# Select bottom pane and run htop
tmux select-pane -t gpu-monitor:0.1
tmux send-keys -t gpu-monitor:0.1 "printf '\e]11;#162c22\007'" C-m
tmux send-keys -t gpu-monitor:0.1 "htop" C-m

# Attach to the session
tmux attach-session -t gpu-monitor
MONITOR_EOF

chmod +x /tmp/gpu_monitor.sh

# Create the ComfyUI launcher script
cat > /tmp/comfyui_runner.sh << 'COMFYUI_EOF'
#!/bin/bash

# Store PIDs for cleanup
COMFYUI_PID=""
FIREFOX_PID=""

# Cleanup function
cleanup_orange() {
    echo ""
    echo "========================================="
    echo "Shutting down ComfyUI and all services..."
    echo "========================================="
    
    # Kill ComfyUI
    if [ ! -z "$COMFYUI_PID" ] && kill -0 $COMFYUI_PID 2>/dev/null; then
        echo "Stopping ComfyUI (PID: $COMFYUI_PID)..."
        kill $COMFYUI_PID 2>/dev/null
        sleep 1
        kill -9 $COMFYUI_PID 2>/dev/null
    fi
    pkill -f "python main.py" 2>/dev/null
    
    # Kill Firefox
    echo "Closing Firefox..."
    if [ ! -z "$FIREFOX_PID" ] && kill -0 $FIREFOX_PID 2>/dev/null; then
        kill $FIREFOX_PID 2>/dev/null
    fi
    pkill -f "firefox.*localhost:8188" 2>/dev/null
    
    # Kill monitoring terminal
    echo "Closing monitoring terminal..."
    tmux kill-session -t gpu-monitor 2>/dev/null
    pkill -f "gpu_monitor.sh" 2>/dev/null
    
    echo "Cleanup complete!"
    sleep 1
    
    exit 0
}

# Set up trap
trap cleanup_orange EXIT INT TERM SIGTERM SIGHUP

# Navigate to ComfyUI directory
echo "Navigating to ComfyUI directory..."
cd ~/ComfyUI || cd ComfyUI || { 
    echo "ERROR: ComfyUI directory not found!"
    echo "Tried: ~/ComfyUI and ./ComfyUI"
    echo "Press any key to exit..."
    read -n 1
    exit 1
}

# Activate virtual environment
echo "Activating virtual environment..."
source .venv/bin/activate || { 
    echo "ERROR: Failed to activate virtual environment!"
    echo "Make sure .venv exists in the ComfyUI directory"
    echo "Press any key to exit..."
    read -n 1
    exit 1
}

# Start ComfyUI
echo ""
echo "========================================="
echo "Starting ComfyUI..."
echo "========================================="
python main.py &
COMFYUI_PID=$!

# Wait for ComfyUI to start
echo "Waiting for ComfyUI to be ready on port 8188..."
for i in {1..60}; do
    if command -v nc &> /dev/null; then
        if nc -z localhost 8188 2>/dev/null; then
            echo "✓ ComfyUI is ready!"
            break
        fi
    else
        # Fallback if nc is not available
        if curl -s http://localhost:8188 > /dev/null 2>&1; then
            echo "✓ ComfyUI is ready!"
            break
        fi
    fi
    
    if [ $i -eq 60 ]; then
        echo "WARNING: ComfyUI may not have started properly"
        echo "Opening Firefox anyway..."
    fi
    
    sleep 1
done

sleep 2

# Open Firefox
echo "Opening Firefox at http://localhost:8188..."
firefox --new-window http://localhost:8188 &
FIREFOX_PID=$!

echo ""
echo "========================================="
echo "ComfyUI is running!"
echo "========================================="
echo "ComfyUI PID: $COMFYUI_PID"
echo "Firefox PID: $FIREFOX_PID"
echo ""
echo "Close Firefox or this terminal to shutdown"
echo "========================================="

# Monitor Firefox and ComfyUI processes
while true; do
    # Check if Firefox is still running
    if ! kill -0 $FIREFOX_PID 2>/dev/null && ! pgrep -f "firefox.*localhost:8188" > /dev/null; then
        echo ""
        echo "Firefox closed - initiating shutdown..."
        cleanup_orange
    fi
    
    # Check if ComfyUI is still running
    if ! kill -0 $COMFYUI_PID 2>/dev/null; then
        echo ""
        echo "ComfyUI process ended - initiating shutdown..."
        cleanup_orange
    fi
    
    sleep 2
done
COMFYUI_EOF

chmod +x /tmp/comfyui_runner.sh

# Launch monitoring terminal
echo "Launching GPU monitoring terminal..."
case $TERMINAL in
    gnome-terminal)
        gnome-terminal --title="GPU Monitor" -- bash -c "/tmp/gpu_monitor.sh" &
        ;;
    konsole)
        konsole --title "GPU Monitor" -e bash -c "/tmp/gpu_monitor.sh" &
        ;;
    xterm)
        xterm -bg "$GREEN_BG" -fg "$GREEN_FG" -title "GPU Monitor" -e bash -c "/tmp/gpu_monitor.sh" &
        ;;
    xfce4-terminal)
        xfce4-terminal --title="GPU Monitor" -e "bash -c /tmp/gpu_monitor.sh" &
        ;;
esac

sleep 1

# Launch orange terminal with ComfyUI
echo "Launching ComfyUI in orange terminal..."
case $TERMINAL in
    gnome-terminal)
        gnome-terminal --title="ComfyUI" -- bash -c "
            printf '\e]10;$ORANGE_FG\007'
            printf '\e]11;$ORANGE_BG\007'
            /tmp/comfyui_runner.sh
        " &
        ;;
    konsole)
        konsole --title "ComfyUI" -e bash -c "
            printf '\e]10;$ORANGE_FG\007'
            printf '\e]11;$ORANGE_BG\007'
            /tmp/comfyui_runner.sh
        " &
        ;;
    xterm)
        xterm -bg "$ORANGE_BG" -fg "$ORANGE_FG" -title "ComfyUI" -e bash -c "/tmp/comfyui_runner.sh" &
        ;;
    xfce4-terminal)
        xfce4-terminal --title="ComfyUI" --color-bg="$ORANGE_BG" --color-text="$ORANGE_FG" -e "bash -c /tmp/comfyui_runner.sh" &
        ;;
esac

# Wait for terminals to open
sleep 2

echo "All terminals launched successfully!"
MAIN_EOF

chmod +x /tmp/comfyui_main_launcher.sh

# Now launch the main script in a detached terminal that closes immediately
case $TERMINAL in
    gnome-terminal)
        gnome-terminal -- bash -c "/tmp/comfyui_main_launcher.sh; exit" &
        ;;
    konsole)
        konsole -e bash -c "/tmp/comfyui_main_launcher.sh; exit" &
        ;;
    xterm)
        xterm -e bash -c "/tmp/comfyui_main_launcher.sh; exit" &
        ;;
    xfce4-terminal)
        xfce4-terminal -e "bash -c '/tmp/comfyui_main_launcher.sh; exit'" &
        ;;
esac

# Give it a moment to start
sleep 1

# Now exit this script - this will close the original terminal
exit 0
LAUNCHER_EOF

print_success "Launcher script created at ~/ComfyUI/comfy_launcher.sh"
echo ""

# Step 8: Make launcher executable
print_message "Step 7: Making launcher script executable..."
chmod +x ~/ComfyUI/comfy_launcher.sh
print_success "Launcher script is now executable"
echo ""

# Final message
echo ""
echo "================================================================"
print_success "ComfyUI installation completed successfully!"
echo "================================================================"
echo ""
echo "Installation summary:"
echo "  • ComfyUI installed at: ~/ComfyUI"
echo "  • ComfyUI Manager installed in: ~/ComfyUI/custom_nodes/ComfyUI-Manager"
echo "  • Virtual environment created at: ~/ComfyUI/.venv"
echo "  • Launcher script: ~/ComfyUI/comfy_launcher.sh"
echo ""
echo "To launch ComfyUI, run:"
echo "  cd ~/ComfyUI && ./comfy_launcher.sh"
echo ""
echo "Or add this to your .bashrc for easy access:"
echo "  alias comfyui='cd ~/ComfyUI && ./comfy_launcher.sh'"
echo ""
echo "================================================================"
