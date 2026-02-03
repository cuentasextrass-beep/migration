#!/bin/bash
# Open a new terminal with the specified profile and run the SSH command
gnome-terminal --profile=55a107da-7c7c-4e45-81b5-f39144f10eda -- bash -c 'ssh SudoTom@192.168.3.2 -p 22; exec bash'

