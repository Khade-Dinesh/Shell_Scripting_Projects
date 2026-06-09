#!/bin/bash
# =============================================================
#  Project   : User Management Automation Script
#  Description: A full-featured interactive script for creating,
#               deleting, modifying, listing, and locking Linux
#               system users and groups.
# =============================================================

# ─── CONFIGURATION ────────────────────────────────────────────
LOG_FILE="/var/log/user_management.log"
DEFAULT_SHELL="/bin/bash"
MIN_UID=1000
DATE=$(date '+%Y-%m-%d %H:%M:%S')

# ─── COLORS ───────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'
GREEN='\033[0;32m'; CYAN='\033[0;36m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

# ─── PRIVILEGE CHECK ──────────────────────────────────────────
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root."
    echo "       Try: sudo $0"
    exit 1
fi

# ─── LOGGING ──────────────────────────────────────────────────
mkdir -p "$(dirname "$LOG_FILE")"

log()       { echo "[$DATE] [INFO]  $1" >> "$LOG_FILE"; }
log_warn()  { echo "[$DATE] [WARN]  $1" >> "$LOG_FILE"; }
log_error() { echo "[$DATE] [ERROR] $1" >> "$LOG_FILE"; }
log_audit() { echo "[$DATE] [AUDIT] by $(who am i | awk '{print $1}') — $1" >> "$LOG_FILE"; }

# ─── HELPERS ──────────────────────────────────────────────────

print_banner() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "  ╔══════════════════════════════════════════╗"
    echo "  ║     USER MANAGEMENT AUTOMATION TOOL     ║"
    echo "  ║          Host: $(hostname)              ║"
    echo "  ╚══════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_section() {
    echo ""
    echo -e "${BOLD}${BLUE}── $1 ──────────────────────────────────────${NC}"
    echo ""
}

confirm() {
    read -p "  Are you sure? [y/N]: " CONFIRM
    [[ "$CONFIRM" =~ ^[Yy]$ ]]
}

user_exists() { id "$1" &>/dev/null; }
group_exists() { getent group "$1" &>/dev/null; }

validate_username() {
    [[ "$1" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]
}

# ─── 1. CREATE USER ───────────────────────────────────────────
create_user() {
    print_section "Create New User"

    read -p "  Enter username      : " USERNAME
    if ! validate_username "$USERNAME"; then
        echo -e "  ${RED}Invalid username.${NC} Use lowercase letters, numbers, _ or - (max 32 chars)."
        return 1
    fi

    if user_exists "$USERNAME"; then
        echo -e "  ${YELLOW}User '$USERNAME' already exists.${NC}"
        log_warn "Attempted to create existing user: $USERNAME"
        return 1
    fi

    read -p "  Full name (optional): " FULL_NAME
    read -p "  Primary group       : " PRIMARY_GROUP
    read -p "  Additional groups   : " EXTRA_GROUPS
    read -p "  Home directory      : " HOME_DIR
    HOME_DIR="${HOME_DIR:-/home/$USERNAME}"
    read -p "  Shell [$DEFAULT_SHELL]: " USER_SHELL
    USER_SHELL="${USER_SHELL:-$DEFAULT_SHELL}"

    echo ""
    echo "  Summary:"
    echo "    Username    : $USERNAME"
    echo "    Full name   : ${FULL_NAME:-N/A}"
    echo "    Home dir    : $HOME_DIR"
    echo "    Shell       : $USER_SHELL"
    echo "    Groups      : ${PRIMARY_GROUP:-auto} / ${EXTRA_GROUPS:-none}"
    echo ""

    confirm || { echo "  Cancelled."; return 0; }

    # Build the useradd command
    USERADD_CMD="useradd -m -d $HOME_DIR -s $USER_SHELL"
    [ -n "$FULL_NAME"     ] && USERADD_CMD="$USERADD_CMD -c \"$FULL_NAME\""
    [ -n "$PRIMARY_GROUP" ] && group_exists "$PRIMARY_GROUP" && \
        USERADD_CMD="$USERADD_CMD -g $PRIMARY_GROUP"
    [ -n "$EXTRA_GROUPS"  ] && USERADD_CMD="$USERADD_CMD -G $EXTRA_GROUPS"
    USERADD_CMD="$USERADD_CMD $USERNAME"

    eval "$USERADD_CMD"

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN}✅ User '$USERNAME' created.${NC}"
        echo ""

        # Set password
        echo "  Set password for '$USERNAME':"
        passwd "$USERNAME"

        # Force password change on first login
        read -p "  Force password change on first login? [Y/n]: " FORCE_PASS
        [[ ! "$FORCE_PASS" =~ ^[Nn]$ ]] && passwd -e "$USERNAME" && \
            echo -e "  ${CYAN}Password expiry set.${NC}"

        log_audit "Created user: $USERNAME (home: $HOME_DIR, shell: $USER_SHELL)"
        echo -e "  ${GREEN}User '$USERNAME' is ready!${NC}"
    else
        echo -e "  ${RED}Failed to create user '$USERNAME'.${NC}"
        log_error "Failed to create user: $USERNAME"
    fi
}

# ─── 2. DELETE USER ───────────────────────────────────────────
delete_user() {
    print_section "Delete User"

    read -p "  Enter username to delete: " USERNAME

    if ! user_exists "$USERNAME"; then
        echo -e "  ${YELLOW}User '$USERNAME' does not exist.${NC}"
        return 1
    fi

    echo ""
    echo "  User Info:"
    id "$USERNAME"
    echo "  Home: $(getent passwd "$USERNAME" | cut -d: -f6)"
    echo ""

    read -p "  Also delete home directory and mail? [y/N]: " DEL_HOME

    confirm || { echo "  Cancelled."; return 0; }

    if [[ "$DEL_HOME" =~ ^[Yy]$ ]]; then
        userdel -r "$USERNAME"
    else
        userdel "$USERNAME"
    fi

    if [ $? -eq 0 ]; then
        echo -e "  ${GREEN} User '$USERNAME' deleted.${NC}"
        log_audit "Deleted user: $USERNAME (home removed: $DEL_HOME)"
    else
        echo -e "  ${RED}Failed to delete user '$USERNAME'.${NC}"
        log_error "Failed to delete user: $USERNAME"
    fi
}

# ─── 3. MODIFY USER ───────────────────────────────────────────
modify_user() {
    print_section "Modify User"

    read -p "  Enter username to modify: " USERNAME

    if ! user_exists "$USERNAME"; then
        echo -e "  ${YELLOW}User '$USERNAME' does not exist.${NC}"
        return 1
    fi

    echo ""
    echo "  What would you like to change?"
    echo "  1. Change password"
    echo "  2. Change shell"
    echo "  3. Add to group"
    echo "  4. Remove from group"
    echo "  5. Change full name (GECOS)"
    echo "  6. Lock account"
    echo "  7. Unlock account"
    echo "  8. Back"
    echo ""
    read -p "  Choose: " MOD_CHOICE

    case $MOD_CHOICE in
        1) passwd "$USERNAME"
           log_audit "Changed password for: $USERNAME" ;;
        2) read -p "  New shell: " NEW_SHELL
           usermod -s "$NEW_SHELL" "$USERNAME" && \
           echo -e "  ${GREEN} Shell updated.${NC}" && \
           log_audit "Changed shell for $USERNAME to $NEW_SHELL" ;;
        3) read -p "  Group name: " GRP
           usermod -aG "$GRP" "$USERNAME" && \
           echo -e "  ${GREEN} Added to group '$GRP'.${NC}" && \
           log_audit "Added $USERNAME to group $GRP" ;;
        4) read -p "  Group to remove from: " GRP
           gpasswd -d "$USERNAME" "$GRP" && \
           echo -e "  ${GREEN} Removed from group '$GRP'.${NC}" && \
           log_audit "Removed $USERNAME from group $GRP" ;;
        5) read -p "  New full name: " NEW_NAME
           usermod -c "$NEW_NAME" "$USERNAME" && \
           echo -e "  ${GREEN} Full name updated.${NC}" ;;
        6) usermod -L "$USERNAME" && \
           echo -e "  ${YELLOW} Account '$USERNAME' locked.${NC}" && \
           log_audit "Locked account: $USERNAME" ;;
        7) usermod -U "$USERNAME" && \
           echo -e "  ${GREEN} Account '$USERNAME' unlocked.${NC}" && \
           log_audit "Unlocked account: $USERNAME" ;;
        8) return ;;
        *) echo "  Invalid option." ;;
    esac
}

# ─── 4. LIST USERS ────────────────────────────────────────────
list_users() {
    print_section "System Users"

    printf "  ${BOLD}%-20s %-6s %-25s %-20s %s${NC}\n" \
        "USERNAME" "UID" "HOME" "SHELL" "STATUS"
    echo "  ─────────────────────────────────────────────────────────────────────────"

    while IFS=: read -r USER PASS UID GID GECOS HOME SHELL; do
        [ "$UID" -lt "$MIN_UID" ] && continue
        [ "$USER" = "nobody" ] && continue

        # Check if account is locked
        STATUS="active"
        passwd -S "$USER" 2>/dev/null | grep -q " L " && STATUS="locked"

        printf "  %-20s %-6s %-25s %-20s %s\n" \
            "$USER" "$UID" "$HOME" "$SHELL" "$STATUS"
    done < /etc/passwd

    echo ""
    TOTAL=$(awk -F: -v min="$MIN_UID" '$3 >= min && $1 != "nobody" {count++} END {print count+0}' /etc/passwd)
    echo "  Total regular users: $TOTAL"
}

# ─── 5. GROUP MANAGEMENT ──────────────────────────────────────
manage_groups() {
    print_section "Group Management"
    echo "  1. Create group"
    echo "  2. Delete group"
    echo "  3. List all groups"
    echo "  4. Show group members"
    echo "  5. Back"
    echo ""
    read -p "  Choose: " GRP_CHOICE

    case $GRP_CHOICE in
        1) read -p "  Group name: " GRP_NAME
           groupadd "$GRP_NAME" && \
           echo -e "  ${GREEN} Group '$GRP_NAME' created.${NC}" && \
           log_audit "Created group: $GRP_NAME" ;;
        2) read -p "  Group to delete: " GRP_NAME
           confirm || return
           groupdel "$GRP_NAME" && \
           echo -e "  ${GREEN} Group '$GRP_NAME' deleted.${NC}" && \
           log_audit "Deleted group: $GRP_NAME" ;;
        3) echo ""; getent group | awk -F: '{printf "  %-20s GID:%-6s Members: %s\n",$1,$3,$4}' ;;
        4) read -p "  Group name: " GRP_NAME
           echo ""
           getent group "$GRP_NAME" | awk -F: '{print "  Members: "$4}' ;;
        5) return ;;
        *) echo "  Invalid option." ;;
    esac
}

# ─── 6. SHOW AUDIT LOG ────────────────────────────────────────
show_audit_log() {
    print_section "Audit Log (last 20 entries)"
    if [ -f "$LOG_FILE" ]; then
        tail -n 20 "$LOG_FILE"
    else
        echo "  No log entries yet."
    fi
}

# ─── MAIN MENU ────────────────────────────────────────────────
main_menu() {
    while true; do
        print_banner
        echo "  1.   Create User"
        echo "  2.   Delete User"
        echo "  3.   Modify User"
        echo "  4.   List Users"
        echo "  5.   Group Management"
        echo "  6.   View Audit Log"
        echo "  7.   Exit"
        echo ""
        read -p "  Choose an option [1-7]: " MAIN_CHOICE
        echo ""

        case $MAIN_CHOICE in
            1) create_user ;;
            2) delete_user ;;
            3) modify_user ;;
            4) list_users ;;
            5) manage_groups ;;
            6) show_audit_log ;;
            7) echo "  Goodbye!"; log "Session ended."; exit 0 ;;
            *) echo -e "  ${RED}Invalid option. Please choose 1-7.${NC}" ;;
        esac

        echo ""
        read -p "  Press Enter to return to menu..."
    done
}

# ─── ENTRY POINT ──────────────────────────────────────────────
log "Session started by $(who am i | awk '{print $1}')"
main_menu
