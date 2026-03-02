#!/usr/bin/env bash

# Configuration
COMMAND_NAME="sso"
SOURCE_URL="https://raw.githubusercontent.com/FuzzyVee/Over-The-Wire-Bandit-Easy-Connect/refs/heads/main/command.sh"
MAN_URL="https://raw.githubusercontent.com/FuzzyVee/Over-The-Wire-Bandit-Easy-Connect/refs/heads/main/sso.1"

INSTALL_PATH="/usr/local/bin/$COMMAND_NAME"
MAN_PATH="/usr/local/share/man/man1/$COMMAND_NAME.1"

echo "--- Installing $COMMAND_NAME ---"

#  Check for dependencies (sshpass)
if ! command -v sshpass &> /dev/null; then
    echo "Dependency 'sshpass' not found. Attempting to install..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y sshpass
    elif command -v brew &> /dev/null; then
        brew install esolitos/ipa/sshpass # Note: might work?
    else
        echo "Could not auto-install sshpass. Please install it manually."
    fi
fi


#  Download files to tmp
echo "Downloading source and manual..."
curl -sSL "$SOURCE_URL" -o /tmp/"$COMMAND_NAME"
curl -sSL "$MAN_URL" -o /tmp/"$COMMAND_NAME".1

#  Check if downloads were successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to download files."
    exit 1
fi

#  Install Executable
echo "Installing executable to $INSTALL_PATH..."
sudo mv /tmp/"$COMMAND_NAME" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

#  Install Man pagina
echo "Installing manual page..."
sudo mkdir -p /usr/local/share/man/man1
sudo mv /tmp/"$COMMAND_NAME".1 "$MAN_PATH"

sudo mandb -q 2>/dev/null

if [ -f "$INSTALL_PATH" ]; then
    echo "Done"
else
    echo "Installation failed."
fi

