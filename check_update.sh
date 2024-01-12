#!/bin/bash

# Define where to install the scripts
install_dir="$HOME/check"

# URL of the GitHub repository branch
repo_url="https://github.com/zhk3r/check"
branch="testing"

# Clone the repository
git clone --branch "$branch" "$repo_url" "$install_dir"

# Change file permissions to executable
find "$install_dir" -type f -exec chmod +x {} \;

echo "Installation complete. Please restart your shell or source your .bashrc/.zshrc file."
echo
echo "Recommend you alias check.sh to check for simplicity"
