#!/bin/bash

# Save the current directory
CURRENT_DIR=$(pwd)

# Navigate to the check-function repository
cd ~/check/check_function.zsh

# Pull the latest changes
git pull

# Return to the original directory
cd $CURRENT_DIR

echo "check function updated successfully."
