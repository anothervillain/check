#!/bin/bash

sudo apt update
# Dependencies
sudo apt install -y git whois openssl dig curl grc boxes python3 python3-pip
# Install pip3 packages with sudo for system-wide installation
sudo pip3 install tabulate
sudo pip3 install colorama
# Install check testing branch
install_dir="$HOME/check"
repo_url="https://github.com/zhk3r/check.git"
branch="testing"
git clone --branch "$branch" "$repo_url" "$install_dir"
# Make all downloaded scripts executable
find "$install_dir" -type f -iname "*.sh" -exec chmod +x {} \;
find "$install_dir" -type f -iname "*.py" -exec chmod +x {} \;
