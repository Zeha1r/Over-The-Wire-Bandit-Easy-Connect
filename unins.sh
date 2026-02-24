#$SHELL

if grep -q "sso" ~/.bashrc; then
    sed -i '/sso/d' ~/.bashrc
fi
