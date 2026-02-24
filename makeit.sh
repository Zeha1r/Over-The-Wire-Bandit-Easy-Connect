#$SHELL
echo "Know that this file should either be executed with sudo or make manually /etc/otw/passwds.txt"
mkdir -p $HOME/etc/otw/ && touch $HOME/etc/otw/passwds.txt
echo "
sso() {
        local OPTIND=1
        local opt
        local PICK_LEVEL=""
        local PASS_FILE="$HOME/etc/otw/passwds.txt"
        local KEY_DIR="$HOME/etc/otw/keys"

        mkdir -p "$KEY_DIR"
        touch "$PASS_FILE"

        # 1. Handle Flags
        while getopts "p:l" opt; do
            case $opt in
                p) PICK_LEVEL="$OPTARG" ;;
                l) column -t -s ':' "$PASS_FILE"; return 0 ;;
                *) return 1 ;;
            esac
        done
        shift $((OPTIND - 1))

        #Helper to find the latest logic 
        local LATEST_LEVEL=$(cut -d':' -f1 "$PASS_FILE" | grep -oE '[0-9]+' | sort -n | tail -n 1)
        [ -z "$LATEST_LEVEL" ] && LATEST_LEVEL=0

        # 2. Logic: Explicit Level Pick (-p 5 [password])
        if [ -n "$PICK_LEVEL" ]; then
            local LEVEL="bandit$PICK_LEVEL"
            local KEY_PATH="$KEY_DIR/$LEVEL.key"
            
            # If a password was provided as an extra argument after the flags
            if [ $# -eq 1 ]; then
                local PASS_TRY="$1"
                echo "Attempting to connect to $LEVEL with provided password..."
                
                if sshpass -p "$PASS_TRY" ssh "$LEVEL@bandit.labs.overthewire.org" -p 2220 -o ConnectTimeout=5 -o StrictHostKeyChecking=no; then
                # If successful, save it to your passwds.txt
                sed -i "/^$LEVEL:/d" "$PASS_FILE"
                echo "$LEVEL:$PASS_TRY" >> "$PASS_FILE"
                [ -f "$KEY_PATH" ] && rm "$KEY_PATH"
                echo "Successfully saved password for $LEVEL."
                fi
                return 0
            fi

            # Default behavior: If no password provided, use saved credentials
            local ENTRY=$(grep "^$LEVEL:" "$PASS_FILE")
            local VAL=$(echo "$ENTRY" | cut -d':' -f2)

            echo "Logging into $LEVEL using saved credentials..."
            if [ -f "$KEY_PATH" ]; then
                ssh -i "$KEY_PATH" "$LEVEL@bandit.labs.overthewire.org" -p 2220
            elif [ -n "$VAL" ]; then
                sshpass -p "$VAL" ssh "$LEVEL@bandit.labs.overthewire.org" -p 2220
            else
                echo "No saved password for $LEVEL. Try: sso -p $PICK_LEVEL <password>"
            fi
            return 0
        fi

        # 3. Logic: One Argument (Password OR Key File)
        if [ $# -eq 1 ]; then
            local INPUT="$1"
            local LAST_NUM=$(tail -n 1 "$PASS_FILE" | cut -d':' -f1 | grep -oE '[0-9]+')
            [ -z "$LAST_NUM" ] && LAST_NUM=0
            local NEXT_NUM=$((LATEST_LEVEL + 1))
            local KEY_PATH="$KEY_DIR/bandit$NEXT_NUM.key"

            echo "Testing credentials for: bandit$NEXT_NUM"

            # Check if input is a file (SSH Key)
            if [ -f "$INPUT" ]; then
                cp "$INPUT" "$KEY_PATH"
                chmod 600 "$KEY_PATH"
                if ssh -i "$KEY_PATH" "bandit$NEXT_NUM@bandit.labs.overthewire.org" -p 2220 -o BatchMode=yes -o ConnectTimeout=5; then
                # Save entry with placeholder for keys
                sed -i "/^bandit$NEXT_NUM:/d" "$PASS_FILE"
                echo "bandit$NEXT_NUM:[KEY_AUTH]" >> "$PASS_FILE"
                else
                rm "$KEY_PATH"
                echo "Key failed for bandit$NEXT_NUM"
                fi
            else
                # Treat as Password
                if sshpass -p "$INPUT" ssh "bandit$NEXT_NUM@bandit.labs.overthewire.org" -p 2220 -o ConnectTimeout=5 -o StrictHostKeyChecking=no; then
                sed -i "/^bandit$NEXT_NUM:/d" "$PASS_FILE"
                echo "bandit$NEXT_NUM:$INPUT" >> "$PASS_FILE"
                [ -f "$KEY_PATH" ] && rm "$KEY_PATH" # Clear old key if password is now used
                fi
            fi

        # 4. Logic: Zero Arguments (Latest Saved)
        elif [ $# -eq 0 ]; then
            if [ "$LATEST_LEVEL" -eq 0 ]; then
                echo "No saved progress found."
                return 1
            fi

            local LEVEL="bandit$LATEST_LEVEL"
            local ENTRY=$(grep "^$LEVEL:" "$PASS_FILE")
            local VAL=$(echo "$ENTRY" | cut -d':' -f2)
            local KEY_PATH="$KEY_DIR/$LEVEL.key"

            echo "Logging into highest reached: $LEVEL"
            if [ -f "$KEY_PATH" ]; then
                ssh -i "$KEY_PATH" "$LEVEL@bandit.labs.overthewire.org" -p 2220
            else
                sshpass -p "$VAL" ssh "$LEVEL@bandit.labs.overthewire.org" -p 2220
            fi
        fi
}
" >> $HOME/.bashrc
