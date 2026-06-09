# 💾 Monitoring Free Disk Space & Sending Email Alerts

A Bash script that scans all mounted filesystems, reports disk usage, and automatically sends email alerts when usage exceeds configurable warning or critical thresholds.

---

## 📋 Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Usage](#usage)
- [Output](#output)
- [Email Alert Setup](#email-alert-setup)
- [Automating with Cron](#automating-with-cron)
- [Log Files](#log-files)

---

## ✨ Features
- Scans **all mounted filesystems** automatically
- Two alert levels: **⚠️ Warning** and **🔴 Critical**
- Automatically **skips** virtual filesystems (`tmpfs`, `devtmpfs`, etc.)
- Sends a **formatted email report** with a full disk summary
- Saves a **local report file** for each alert event
- Fully **configurable** thresholds, email, and skip list
- Supports both `sendmail` and `mail` utilities

---

## 🔧 Prerequisites

| Tool | Purpose |
|------|---------|
| `bash` | Script interpreter |
| `df` | Disk usage statistics |
| `sendmail` or `mail` | Sending email alerts |
| `awk`, `grep` | Parsing output |

Install mail utilities:
```bash
# Debian / Ubuntu
sudo apt install mailutils postfix

# RHEL / CentOS
sudo yum install mailx postfix
```

---

## ⚙️ Configuration

Edit the configuration block at the top of `monitor_disk_alert.sh`:

```bash
THRESHOLD=80                   # Warn if disk usage >= 80%
CRITICAL_THRESHOLD=90          # Critical alert if >= 90%
EMAIL_TO="admin@example.com"   # Alert recipient
EMAIL_FROM="monitor@myserver"  # Sender address
LOG_FILE="/var/log/disk_monitor.log"
ALERT_LOG="/var/log/disk_alerts.log"

# Filesystem types to ignore
SKIP_FS="tmpfs devtmpfs udev squashfs overlay"
```

---

## 🚀 Usage

**Make the script executable:**
```bash
chmod +x monitor_disk_alert.sh
```

**Run the script:**
```bash
./monitor_disk_alert.sh
# or
sudo ./monitor_disk_alert.sh
```

---

## 📊 Output

```
==============================================
   Disk Space Monitor — Host: my-server
   Date : 2025-06-09 14:30:00
   Alert Threshold  : 80%
   Critical Threshold: 90%
==============================================

  Filesystem             Size    Used    Avail   Use%  Mounted On
  -----------------------------------------------------------------------
  /dev/sda1              50G     15G     32G     30%   /         ✅ OK
  /dev/sdb1              200G    175G    20G     88%   /data     🟡 WARNING
  /dev/sdc1              100G    95G     2G      96%   /backup   🔴 CRITICAL

  ⚠️  Alert(s) detected! Sending email to admin@example.com...
  Report saved: /tmp/disk_report_20250609_143000.txt
==============================================
```

---

## 📬 Email Alert Setup

### Option 1 — Postfix (Recommended for servers)
```bash
sudo apt install postfix
sudo systemctl enable postfix
sudo systemctl start postfix
```

### Option 2 — SSMTP (Simple relay)
```bash
sudo apt install ssmtp
# Edit /etc/ssmtp/ssmtp.conf with your SMTP settings
```

### Option 3 — Gmail SMTP via msmtp
```bash
sudo apt install msmtp msmtp-mta
```
Configure `~/.msmtprc` with Gmail credentials.

---

## ⏰ Automating with Cron

Run every hour:
```bash
crontab -e
```
Add:
```cron
0 * * * * /path/to/monitor_disk_alert.sh >> /var/log/disk_monitor.log 2>&1
```

Run at 8 AM every day:
```cron
0 8 * * * /path/to/monitor_disk_alert.sh
```

---

## 📁 Log Files

| File | Contents |
|------|---------|
| `/var/log/disk_monitor.log` | Full log of every check with timestamps |
| `/var/log/disk_alerts.log` | Alerts only (WARNING / CRITICAL) |
| `/tmp/disk_report_<timestamp>.txt` | Saved report for each alert event |

---

## 📄 License
MIT — free to use and modify.
