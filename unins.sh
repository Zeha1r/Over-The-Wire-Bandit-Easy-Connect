#$SHELL

if grep -q "sso" ~/.bashrc; then
    sed -i '/sso/d' ~/.bashrc
    echo "Bashrc Command text added."
fi
if [ -d "$HOME/etc/otw" ]; then
    rm -rf "$HOME/etc/otw"
    echo "Directory Otw deleted."
fi
