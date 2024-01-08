#!/bin/bash

# Update package lists
sudo apt update

# Install dependencies with automatic 'yes' to prompts
sudo apt install -y whois openssl curl lolcat python3 python3-pip

# Install pip3 packages with sudo for system-wide installation
sudo pip3 install tabulate
sudo pip3 install colorama

# Define where to install the scripts
install_dir="$HOME/check"

# URLs of the raw scripts from the GitHub repository
repo_base_url="https://raw.githubusercontent.com/zhk3r/check/testing"
files=("check.sh" "check_cert.sh" "check_help.sh" "check_host.sh" "check_mail.sh" "check_rdns.sh" "check_ssl.sh" "check_update.sh" "hostguess.py" "rdns.py" "reverse-dns-lookup.py")

# Create the installation directory
mkdir -p "$install_dir"

# Download and install each file
for file in "${files[@]}"; do
    echo "Downloading $file..."
    curl -fsSL "$repo_base_url/$file" -o "$install_dir/$file"
    chmod +x "$install_dir/$file"
done

echo "Installation complete. Please restart your shell or source your .bashrc/.zshrc file."

# Optional: Executing the default shell, you may comment out this line if not needed
exec "$SHELL"
