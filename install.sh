#!/bin/bash

# Define the GitHub repository URL
GITHUB_REPO="https://github.com/zhk3r/check.git"

# Define the directory to clone the repository into
INSTALL_DIR="$HOME/check"

# Clone the GitHub repository
git clone "$GITHUB_REPO" "$INSTALL_DIR"

# Change to the installation directory
cd "$INSTALL_DIR"

# Set execute permissions on rdns.py and update_check.sh
chmod +x rdns.py update_check.sh

# Temporarily store current .zshrc content
TEMP_ZSHRC=$(mktemp)
cat $HOME/.zshrc > $TEMP_ZSHRC

# Prepend export and source paths to the top of .zshrc
{
    echo "export PATH=\$PATH:$INSTALL_DIR"
    echo "source $INSTALL_DIR/check_function.zsh"
    cat $TEMP_ZSHRC
} > $HOME/.zshrc

# Remove temporary file
rm $TEMP_ZSHRC

# Refresh .zshrc to apply changes
source $HOME/.zshrc