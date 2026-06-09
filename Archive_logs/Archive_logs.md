# 🗄️ Archiving Older Log Files Automatically

A Bash script that automatically finds log files older than a specified number of days, compresses them into a dated `.tar.gz` archive, optionally removes the originals, and cleans up stale archives.

---

##  Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Usage](#usage)
- [Dry Run Mode](#dry-run-mode)
- [Output](#output)
- [Automating with Cron](#automating-with-cron)
- [Log Files](#log-files)

---

##  Features
- Recursively scans a source directory for old log files
- Matches multiple file patterns (`*.log`, `*.log.1`, etc.)
- Creates **compressed `.tar.gz` archives** with a date-stamped name
- Optionally **deletes original files** after archiving
- Auto-cleans archives older than a configurable retention period
- **Dry-run mode** to safely preview all actions
- Color-coded terminal output for easy reading
- Logs all operations to its own log file

---

##  Prerequisites

| Tool | Purpose |
|------|---------|
| `bash` | Script interpreter |
| `find` | Locate old log files |
| `tar`, `gzip` | Create compressed archives |
| `du`, `stat` | Show file sizes and dates |

These are standard tools available on all major Linux distributions.

---

##  Configuration

Edit the top section of `archive_logs.sh`:

```bash
LOG_SOURCE_DIR="/var/log"           # Directory to scan
ARCHIVE_BASE_DIR="/var/log/archives"# Where archives are saved
DAYS_OLD=30                         # Archive files older than N days
LOG_EXTENSIONS=("*.log" "*.log.[0-9]*") # File patterns to archive
MAX_ARCHIVE_AGE=90                  # Delete archives older than N days
DELETE_AFTER_ARCHIVE=true           # Remove originals after archiving
DRY_RUN=false                       # true = preview only
```

---

##  Usage

**Make the script executable:**
```bash
chmod +x archive_logs.sh
```

**Run normally:**
```bash
sudo ./archive_logs.sh
```

**Preview without making changes:**
```bash
sudo ./archive_logs.sh --dry-run
```

**Show help:**
```bash
./archive_logs.sh --help
```

---

## Dry Run Mode

Use `--dry-run` to safely preview what the script would do — no files are created, moved, or deleted:

```bash
sudo ./archive_logs.sh --dry-run
```

Example output:
```
[DRY-RUN] Would create archive: /var/log/archives/logs_2025-06-09_20250609_143000.tar.gz
[DRY-RUN] Would include 14 files
[DRY-RUN] Would delete original 14 files after archiving
```

---

## 📊 Output

```
==================================================
    Log Archiver — Host: my-server
    Date         : 2025-06-09
    Source Dir   : /var/log
    Archive Dir  : /var/log/archives
    Archive files older than : 30 days
    Delete after archive     : true
    Dry run mode             : false

   Found 8 file(s) to archive:

     /var/log/syslog.30                      12K   (2025-05-09)
     /var/log/auth.log.30                    4.0K  (2025-05-08)
     ...

   Creating archive: /var/log/archives/logs_2025-06-09_20250609_143000.tar.gz
    Archive created successfully! Size: 2.3M

    Removing original log files...
   Removed 8 original file(s).

   Checking for archives older than 90 days...
   No old archives to clean up.

==================================================
 Archive Summary
  ------------------
  Total archives stored : 3
  Archive directory size: 8.5M
  Archive location      : /var/log/archives
==================================================
```

---

##  Automating with Cron

Run every Sunday at 2 AM:
```bash
crontab -e
```
Add:
```cron
0 2 * * 0 /path/to/archive_logs.sh >> /var/log/archive_manager.log 2>&1
```

Run on the 1st of every month:
```cron
0 3 1 * * /path/to/archive_logs.sh
```

---

##  Log Files

| File | Contents |
|------|---------|
| `/var/log/archive_manager.log` | Full timestamped log of every archiving run |
| `/var/log/archives/*.tar.gz` | Compressed archives of old log files |

---

##  Archive Naming Convention

Archives are named using the format:
```
logs_YYYY-MM-DD_YYYYMMDD_HHMMSS.tar.gz
```
Example: `logs_2025-06-09_20250609_143000.tar.gz`

---

## License
MIT — free to use and modify.
