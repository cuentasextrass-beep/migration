#!/bin/bash
# Define machines
MACHINE1="localhost"  # Current machine
MACHINE2="mares@192.168.2.79"  # Remote machine

# Function to start all workers
start_all_workers() {
    # Start local worker in background
    echo "Starting local Flamenco worker..."
    ./flamenco-3.6/flamenco-worker > local_worker.log 2>&1 &
    local_pid=$!
    echo "Local worker started with PID: $local_pid"
    
    # Start remote worker via direct SSH
    echo "Starting remote Flamenco worker on $MACHINE2..."
    ssh -t $MACHINE2 "cd && ./flamenco-3.6/flamenco-worker" &
    
    echo "Started Flamenco workers on local machine and connected to $MACHINE2"
    echo "To stop workers, use: kill $local_pid and close the SSH session"
}

# Function to start only local worker
start_local_worker() {
    echo "Starting local Flamenco worker..."
    ./flamenco-3.6/flamenco-worker > local_worker.log 2>&1 &
    local_pid=$!
    echo "Local worker started with PID: $local_pid"
    echo "To stop worker, use: kill $local_pid"
}

# Parse command line arguments
if [[ "$1" == "--all" || "$1" == "-a" ]]; then
    echo "Starting Flamenco workers on all machines..."
    start_all_workers
else
    echo "Starting Flamenco worker on local machine only..."
    start_local_worker
fi
