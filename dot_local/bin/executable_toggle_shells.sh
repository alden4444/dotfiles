#!/bin/bash

# Define paths to your isolated shell source directories
CAELESTIA_DIR="$HOME/src/caelestia-shell" # Update this to your actual path
TRIPATHI_DIR="$HOME/src/tripathiji1312-quickshell" # Update this to your actual path

# Check if quickshell is currently running
if pgrep -x "quickshell" > /dev/null; then
    # Look at the active process arguments to see which config is live
    CURRENT_CMD=$(ps -f -C quickshell | grep -v CMD)

    if [[ "$CURRENT_CMD" == *"$TRIPATHI_DIR"* ]]; then
        # If tripathiji1312 is running, kill it and switch to Caelestia
        killall quickshell
        sleep 0.2
        quickshell --path "$CAELESTIA_DIR" &
    else
        # If Caelestia (or anything else) is running, kill it and switch to tripathiji1312
        killall quickshell
        sleep 0.2
        # tripathiji1312 uses pywal cache for colours, make sure it pulls from its directory
        quickshell --path "$TRIPATHI_DIR" &
    fi
else
    # If nothing is running, default to launching tripathiji1312
    quickshell --path "$TRIPATHI_DIR" &
fi
