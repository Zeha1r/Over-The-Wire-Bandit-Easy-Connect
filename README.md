# Bandit SSO (sso)

A streamlined Bash utility for managing OverTheWire Bandit wargame credentials and SSH connections. It automates the process of saving passwords, handling SSH keys, and logging into levels.

---

## Features

* **Auto-Advance:** Provide a password or key, and the script automatically attempts to unlock the next level.
* **Credential Management:** Saves successful passwords to ~/etc/otw/passwds.txt.
* **SSH Key Support:** Automatically handles private key files and sets correct permissions (600).
* **Quick Connect:** Run sso with no arguments to jump straight into your highest reached level.
* **Session Persistence:** Uses sshpass for seamless, non-interactive logins.

---

## Installation

1.  **Install Dependencies:**
    ```bash
    sudo apt update && sudo apt install sshpass openssh-client
    ```

2.  **Add to Shell Profile:**
    Append the sso() function code to your ~/.bashrc or ~/.zshrc file.

3.  **Apply Changes:**
    ```bash
    source ~/.bashrc
    ```

---

## Usage

| Command | Description |
| :--- | :--- |
| sso | Connect to the highest reached level saved in your history. |
| sso <password> | Test a password for the next level. If successful, it is saved. |
| sso <file_path> | Test an SSH Key for the next level. If successful, it is imported. |
| sso -p <num> | Connect to Level <num> using previously saved credentials. |
| sso -p <num> <pass> | Manually set or update the password for Level <num>. |
| sso -l | List all saved levels and passwords in a clean table format. |

---

## Data Storage

The script creates and maintains a local directory structure for your progress:

* **Passwords:** ~/etc/otw/passwds.txt
* **SSH Keys:** ~/etc/otw/keys/banditX.key

---

## Requirements

* **sshpass:** Required for automated password entry.
* **Standard Linux Utilities:** grep, sed, awk, column, sort.

Note: This tool is designed for the OverTheWire educational environment. Always practice secure credential management in production environments.

###Thx Gemini for saving me from writing the readme tables.
