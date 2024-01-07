#!/bin/bash

# Define where to install the scripts
install_dir="$HOME/check"

# URLs of the raw scripts from the GitHub repository
repo_base_url="https://raw.githubusercontent.com/zhk3r/check/testing"
files=("check.sh" "check_cert.sh" "check_help.sh" "check_host.sh" "check_mail.sh" "check_rdns.sh" "check_ssl.sh" "hostguess.py" "rdns.py" "reverse-dns-lookup.py")

# Create the installation directory
mkdir -p "$install_dir"

# Download and install each file
for file in "${files[@]}"; do
    echo "Downloading $file..."
    curl -fsSL "$repo_base_url/$file" -o "$install_dir/$file"
    chmod +x "$install_dir/$file"
done

# Add the install directory to PATH in .bashrc and .zshrc
update_path() {
    local shell_rc="$1"
    if [ -f "$shell_rc" ]; then
        if ! grep -q "export PATH=\"$install_dir:\$PATH\"" "$shell_rc"; then
            echo "Updating $shell_rc..."
            echo "export PATH=\"$install_dir:\$PATH\"" >> "$shell_rc"
        fi
    fi
}

update_path "$HOME/.bashrc"
update_path "$HOME/.zshrc"

echo "Installation complete. Please restart your shell or source your .bashrc/.zshrc file."
echo
echo "Recommend you alias check.sh to check for simplicity"
