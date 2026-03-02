#!/usr/bin/env bash
# =============================================================================
# sso() - OverTheWire Bandit SSH Connection Manager
# =============================================================================
# Usage:
#   sso                     - Connect to highest reached level
#   sso <password|keyfile>  - Test creds for the next level
#   sso -p <level>          - Connect to a specific level using saved creds
#   sso -p <level> <pass>   - Connect to a specific level with a new password
#   sso -l                  - List all saved credentials
#   sso -h                  - Show this help
# =============================================================================

sso() {
    # -- Constants & Config ---------------------------------------------------
    local -r SSH_HOST="bandit.labs.overthewire.org"
    local -r SSH_PORT=2220
    local -r SSH_TIMEOUT=10
    local -r PASS_FILE="$HOME/.local/share/otwprogress/passwds.txt"
    local -r KEY_DIR="$HOME/.local/share/otwprogress/keys/"
    local -r SSH_COMMON_OPTS="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=$SSH_TIMEOUT"
    # -- Helper Functions -----------------------------------------------------
    _sso_usage() {
        cat <<'EOF'
Usage: sso [OPTIONS] [password|keyfile]

Options:
  -p LEVEL   Pick a specific bandit level (0-33)
  -l         List saved credentials
  -h         Show this help

Examples:
  sso                          Connect to highest saved level
  sso 'some_password'          Test password for the next level
  sso /tmp/sshkey.private      Test SSH key for the next level
  sso -p 5                     Connect to bandit5 with saved creds
  sso -p 5 'some_password'     Connect to bandit5 with a new password
EOF
   }

    _sso_err() { printf '\033[1;31mError:\033[0m %s\n' "$*" >&2; }
    _sso_info() { printf '\033[1;34m>>>\033[0m %s\n' "$*"; }
    _sso_ok() { printf '\033[1;32m>>>\033[0m %s\n' "$*"; }

    _sso_check_deps() {
        local missing=()
        for cmd in ssh sshpass column cut grep sort; do
            command -v "$cmd" &>/dev/null || missing+=("$cmd")
        done
        if (( ${#missing[@]} )); then
            _sso_err "Missing required commands: ${missing[*]}"
            return 1
        fi
    }

    _sso_validate_level() {
        local level="$1"
        if ! [[ "$level" =~ ^[0-9]+$ ]] || (( level < 0 || level > 33 )); then
            _sso_err "Invalid level '$level'. Must be 0-33."
            return 1
        fi
    }

    _sso_get_latest_level() {
        cut -d':' -f1 "$PASS_FILE" 2>/dev/null \
            | grep -oE '[0-9]+' \
            | sort -n \
            | tail -n 1
    }

    _sso_save_password() {
        local level="$1" pass="$2"
        # Remove old entry, then append
        sed -i "/^${level}:/d" "$PASS_FILE"
        echo "${level}:${pass}" >> "$PASS_FILE"
    }

    _sso_connect_key() {
        local user="$1" key="$2"
        ssh -i "$key" ${SSH_COMMON_OPTS} "${user}@${SSH_HOST}" -p "$SSH_PORT"
    }

    _sso_connect_pass() {
        local user="$1" pass="$2"
        sshpass -p "$pass" ssh ${SSH_COMMON_OPTS} "${user}@${SSH_HOST}" -p "$SSH_PORT"
    }

    _sso_test_key() {
        local user="$1" key="$2"
        ssh -i "$key" ${SSH_COMMON_OPTS} -o BatchMode=yes "${user}@${SSH_HOST}" -p "$SSH_PORT" exit 0 2>/dev/null
    }

    _sso_test_pass() {
        local user="$1" pass="$2"
        sshpass -p "$pass" ssh ${SSH_COMMON_OPTS} -o BatchMode=yes "${user}@${SSH_HOST}" -p "$SSH_PORT" exit 0 2>/dev/null
    }

    # -- Preflight Checks -----------------------------------------------------
    _sso_check_deps || return 1

    if [ ! -d "$KEY_DIR" ]; then
        mkdir -p "$KEY_DIR" || { _sso_err "Error creando dir y saliendo"; return 1; }
        chmod 700 "$KEY_DIR"
    fi
    if [ ! -f "$PASS_FILE" ]; then
        touch "$PASS_FILE" || { _sso_err "Error creando archivo y saliendo"; return 1; }
        chmod 600 "$PASS_FILE"
    fi

    # -- Parse Flags ----------------------------------------------------------
    local OPTIND=1 opt
    local PICK_LEVEL=""

    while getopts ":p:lh" opt; do
        case $opt in
            p) PICK_LEVEL="$OPTARG" ;;
            l)
                if [ ! -s "$PASS_FILE" ]; then
                    _sso_info "No saved credentials yet."
                    return 0
                fi
                _sso_info "Saved progress so far:"
                column -t -s ':' "$PASS_FILE"
                return 0
                ;;
            h) _sso_usage; return 0 ;;
            \?) _sso_err "Unknown option: -$OPTARG"; _sso_usage; return 1 ;;
            :)  _sso_err "Option -$OPTARG requires an argument."; return 1 ;;
        esac
    done
    shift $((OPTIND - 1))

    local LATEST_LEVEL
    LATEST_LEVEL=$(_sso_get_latest_level)
    : "${LATEST_LEVEL:=0}"

    # -- Mode 1: Explicit Level Pick (-p LEVEL [password]) --------------------
    if [ -n "$PICK_LEVEL" ]; then
        _sso_validate_level "$PICK_LEVEL" || return 1

        local LEVEL="bandit${PICK_LEVEL}"
        local KEY_PATH="${KEY_DIR}/${LEVEL}.key"

        # Sub-case: password provided as positional arg
        if [ $# -eq 1 ]; then
            local PASS_TRY="$1"
            _sso_info "Testing password for $LEVEL..."

            if _sso_test_pass "$LEVEL" "$PASS_TRY"; then
                _sso_save_password "$LEVEL" "$PASS_TRY"
                [ -f "$KEY_PATH" ] && rm -f "$KEY_PATH"
                _sso_ok "Password saved for $LEVEL. Connecting..."
                _sso_connect_pass "$LEVEL" "$PASS_TRY"
            else
                _sso_err "Authentication failed for $LEVEL."
                return 1
            fi
            return $?

        elif [ $# -gt 1 ]; then
            _sso_err "Too many arguments. Usage: sso -p LEVEL [password]"
            return 1
        fi

        # Sub-case: no password, use saved credentials
        local ENTRY VAL
        ENTRY=$(grep "^${LEVEL}:" "$PASS_FILE")
        VAL=$(echo "$ENTRY" | cut -d':' -f2)

        if [ -f "$KEY_PATH" ]; then
            _sso_info "Connecting to $LEVEL with saved SSH key..."
            _sso_connect_key "$LEVEL" "$KEY_PATH"
        elif [ -n "$VAL" ] && [ "$VAL" != "[KEY_AUTH]" ]; then
            _sso_info "Connecting to $LEVEL with saved password..."
            _sso_connect_pass "$LEVEL" "$VAL"
        else
            _sso_err "No saved credentials for $LEVEL."
            _sso_info "Try: sso -p $PICK_LEVEL <password>"
            return 1
        fi
        return $?
    fi

    # -- Mode 2: One Argument (test next level with password or key) ----------
    if [ $# -eq 1 ]; then
        local INPUT="$1"
        local NEXT_NUM=$((LATEST_LEVEL + 1))
        local NEXT_LEVEL="bandit${NEXT_NUM}"
        local KEY_PATH="${KEY_DIR}/${NEXT_LEVEL}.key"

        _sso_validate_level "$NEXT_NUM" || return 1
        _sso_info "Testing credentials for $NEXT_LEVEL..."

        if [ -f "$INPUT" ]; then
            # Input is a file — treat as SSH key
            cp "$INPUT" "$KEY_PATH" || { _sso_err "Failed to copy key."; return 1; }
            chmod 600 "$KEY_PATH"

            if _sso_test_key "$NEXT_LEVEL" "$KEY_PATH"; then
                _sso_save_password "$NEXT_LEVEL" "[KEY_AUTH]"
                _sso_ok "SSH key works for $NEXT_LEVEL. Connecting..."
                _sso_connect_key "$NEXT_LEVEL" "$KEY_PATH"
            else
                rm -f "$KEY_PATH"
                _sso_err "SSH key authentication failed for $NEXT_LEVEL."
                return 1
            fi
        else
            # Input is a password string
            if _sso_test_pass "$NEXT_LEVEL" "$INPUT"; then
                _sso_save_password "$NEXT_LEVEL" "$INPUT"
                [ -f "$KEY_PATH" ] && rm -f "$KEY_PATH"
                _sso_ok "Password works for $NEXT_LEVEL. Connecting..."
                _sso_connect_pass "$NEXT_LEVEL" "$INPUT"
            else
                _sso_err "Password authentication failed for $NEXT_LEVEL."
                return 1
            fi
        fi
        return $?

    # -- Mode 3: Zero Arguments (reconnect to highest level) ------------------
    elif [ $# -eq 0 ]; then

        if (( LATEST_LEVEL == 0 )); then
            # Special case: bandit0 uses password "bandit0"
            _sso_info "No saved progress. Connecting to bandit0 (password: bandit0)..."
            _sso_connect_pass "bandit0" "bandit0"
            return $?
        fi
        local LEVEL="bandit${LATEST_LEVEL}"
        local ENTRY VAL KEY_PATH
        ENTRY=$(grep "^${LEVEL}:" "$PASS_FILE")
        VAL=$(echo "$ENTRY" | cut -d':' -f2)
        KEY_PATH="${KEY_DIR}/${LEVEL}.key"

        _sso_info "Reconnecting to highest level: $LEVEL"

        if [ -f "$KEY_PATH" ]; then
            _sso_connect_key "$LEVEL" "$KEY_PATH"
        elif [ -n "$VAL" ] && [ "$VAL" != "[KEY_AUTH]" ]; then
            _sso_connect_pass "$LEVEL" "$VAL"
        else
            _sso_err "Saved entry for $LEVEL exists but credentials are missing."
            return 1
        fi
        return $?

    # -- Too many arguments ---------------------------------------------------
    else
        _sso_err "Too many arguments."
        _sso_usage
        return 1
    fi
}
sso $@
