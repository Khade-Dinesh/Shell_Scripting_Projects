# User Management Automation Script

An interactive Bash script for managing Linux system users and groups. Supports creating, deleting, modifying, locking, and listing users — all with full audit logging.

---

##  Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Usage](#usage)
- [Menu Overview](#menu-overview)
- [Functions](#functions)
- [Audit Log](#audit-log)
- [Examples](#examples)

---

## Features
- Interactive menu-driven interface
- **Create** users with custom home, shell, and groups
- **Delete** users with optional home directory removal
- **Modify** users — password, shell, groups, full name
- **Lock / Unlock** user accounts
- **Group management** — create, delete, list, inspect
- Full **audit log** of every action taken
- Color-coded terminal output
- Root privilege enforcement
- Username validation to enforce Linux naming rules

---

## Prerequisites

| Tool | Purpose |
|------|---------|
| `bash` | Script interpreter |
| `useradd`, `userdel`, `usermod` | User management |
| `groupadd`, `groupdel`, `gpasswd` | Group management |
| `passwd` | Password management |
| `getent`, `id` | User/group lookup |

These tools are part of the `shadow-utils` / `passwd` package — installed by default on all major Linux distributions.

---

##  Usage

**Make the script executable:**
```bash
chmod +x user_management.sh
```

**Run as root (required):**
```bash
sudo ./user_management.sh
```

---

##  Menu Overview

```
╔══════════════════════════════════════════╗
║     USER MANAGEMENT AUTOMATION TOOL     ║
╚══════════════════════════════════════════╝

  1. ➕  Create User
  2. ❌  Delete User
  3. ✏️   Modify User
  4. 📋  List Users
  5. 👥  Group Management
  6. 📜  View Audit Log
  7. 🚪  Exit
```

---

##  Functions

### ➕ Create User
Prompts for:
- Username (validated against Linux naming rules)
- Full name (optional)
- Primary group and additional groups
- Home directory (defaults to `/home/username`)
- Login shell (defaults to `/bin/bash`)
- Password + optional forced password change on first login

### ❌ Delete User
- Shows user details before deletion
- Prompts to also remove home directory and mail spool
- Requires confirmation before proceeding

### ✏️ Modify User
Sub-options:
1. Change password
2. Change shell
3. Add to group
4. Remove from group
5. Change full name (GECOS field)
6. Lock account
7. Unlock account

### 📋 List Users
Displays all regular users (UID ≥ 1000) in a formatted table:
```
  USERNAME       UID    HOME                    SHELL                STATUS
  ────────────────────────────────────────────────────────────────
  alice          1001   /home/alice             /bin/bash            active
  bob            1002   /home/bob               /bin/zsh             locked
```

### 👥 Group Management
- Create / delete groups
- List all groups with GIDs and members
- Show members of a specific group

---

## 📜 Audit Log

Every action is logged to `/var/log/user_management.log`:

```
[2025-06-09 14:30:00] [AUDIT] by root — Created user: alice (home: /home/alice, shell: /bin/bash)
[2025-06-09 14:32:10] [AUDIT] by root — Changed password for: alice
[2025-06-09 14:35:00] [AUDIT] by root — Locked account: bob
[2025-06-09 14:40:00] [AUDIT] by root — Deleted user: bob (home removed: y)
```

---

## 🔐 Security Notes

- Script refuses to run without **root** privileges
- Always prompts for **confirmation** before destructive operations
- Usernames are validated to follow Linux naming conventions
- All actions are **logged with timestamp and operator identity**

---

## 💡 Examples

**Create a new developer user:**
```
Username   : devuser
Full name  : Dev User
Groups     : developers, docker
Home       : /home/devuser
Shell      : /bin/bash
```

**Lock a user during offboarding:**
```
Modify User → 6. Lock account → devuser
```

**Add user to sudo group:**
```
Modify User → 3. Add to group → sudo
```

---

## 📄 License
MIT — free to use and modify.
