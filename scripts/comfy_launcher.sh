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
