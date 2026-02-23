#$SHELL
echo "Know that this file should either be executed with sudo or make manually /etc/otw/passwds.txt"
mkdir -p $HOME/etc/otw/ && touch $HOME/etc/otw/passwds.txt
echo "
sso() {
        if [ $# -eq 2 ]; then
                sshpass -p "$2" ssh "bandit$1@bandit.labs.overthewire.org" -p 2220
                STATUS=$?
                if [ $STATUS -eq 0]; then
                        if grep -q "^bandit$1:" "$HOME/etc/otw/passwds.txt"; then
                                sed -i "s|^bandit$1:.*|bandit$1:$2|" "$HOME/etc/otw/passwds.txt"
                        else
                                echo "bandit$1:$2" >> "$HOME/etc/otw/passwds.txt"
                        fi
                fi
        elif [ $# -eq 1 ]; then
                var=$(xclip -selection c -o)
                sshpass -p "$var" ssh "bandit$1@bandit.labs.overthewire.org" -p 2220
                STATUS=$?
                if [ $STATUS -ne 0 ]; then
                        passwdline=$(grep -E "bandit$1:" $HOME/etc/otw/passwds.txt | tail -n 1)
                        passwdcurr=$(echo "$passwdline" | sed -E 's/.*bandit([0-9]+).*/\1/')
                        shpass -p "$passwdcurr" ssh "bandit$1@bandit.labs.overthewire.org" -p 2220
                        STATUS=$?
                        if [ $STATUS -ne 0 ]; then
                                ssh "bandit$1@bandit.labs.overthewire.org" -p 2220
                                if [ $STATUS -eq 0 ]; then
                                        echo "passwd not saved, use 2 args to save progress"
                                fi
                        fi

                fi

        elif [ $# -eq 0 ]; then
                last=$(grep -E "bandit[0-9]*:" $HOME/etc/otw/passwds.txt | tail -n 1)
                num1=$(echo "$last" | sed -E 's/.*bandit([0-9]+).*/\1/' | tr -d "a-zA-Z" )
                num2=$(echo "$last" | cut -d':' -f2-)
                sshpass -p "$num2" ssh "bandit$num1@bandit.labs.overthewire.org" -p 2220
        fi
}
" >> $HOME/.bashrc
