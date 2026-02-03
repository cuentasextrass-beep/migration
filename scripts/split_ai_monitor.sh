#!/bin/bash

# GPU and System Monitor with Split Terminal
# This script creates a tmux session with nvidia-smi (top) and htop (bottom)
# with a dark green background and doubled terminal height

# Kill any existing session with the same name
tmux kill-session -t gpu-monitor 2>/dev/null

# Get current terminal size
current_rows=$(tput lines)
current_cols=$(tput cols)

# Double the height
new_rows=$((current_rows * 2))

# Resize terminal (this works in some terminal emulators)
printf '\e[8;%d;%dt' "$new_rows" "$current_cols"

# Create new tmux session with dark green background
tmux new-session -d -s gpu-monitor -x "$current_cols" -y "$new_rows"

# Set dark green background color for tmux
tmux set-option -t gpu-monitor status-style bg=colour22,fg=colour46
tmux set-option -t gpu-monitor pane-active-border-style fg=colour46
tmux set-option -t gpu-monitor pane-border-style fg=colour22

# Set dark green background for the terminal content
# Using ANSI escape codes for green background
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
