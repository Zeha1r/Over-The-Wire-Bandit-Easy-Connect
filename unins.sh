#!/usr/bin/env bash

COMMAND_NAME="sso"
INSTALL_PATH="/usr/local/bin/$COMMAND_NAME"
MAN_PATH="/usr/local/share/man/man1/$COMMAND_NAME.1"

echo -n "--- Uninstalling $COMMAND_NAME---"

# Remove the executable
if [ -f "$INSTALL_PATH" ]; then
    sudo rm -rf "$INSTALL_PATH"
    echo -n "Removed $INSTALL_PATH"
fi

# Remove the EM-manuel
if [ -f "$MAN_PATH" ]; then
    sudo rm -rf "$MAN_PATH"
    echo -n "Removed $MAN_PATH"
fi

# Update man db wich idk how it works but buen practica 
sudo mandb -q 2>/dev/null

echo "Uninstallation complete, Dependencies untouched, remove sshpass at your own will."
