#!/bin/bash

# Update package lists
sudo apt update

# Install dependencies with automatic 'yes' to prompts
sudo apt install -y git whois openssl dig curl lolcat grc boxes zsh python3 python3-pip

# Install pip3 packages with sudo for system-wide installation
sudo pip3 install tabulate
sudo pip3 install colorama

# Define where to install the scripts
install_dir="$HOME/check"

# Clone the entire repository
repo_url="https://github.com/zhk3r/check.git"
branch="testing"
git clone --branch "$branch" "$repo_url" "$install_dir"

# Make all downloaded scripts executable
find "$install_dir" -type f -iname "*.sh" -exec chmod +x {} \;
find "$install_dir" -type f -iname "*.py" -exec chmod +x {} \;
