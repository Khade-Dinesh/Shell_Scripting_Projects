# 🖥️ Monitoring Free RAM Space

A lightweight Bash script that monitors available system RAM, logs usage statistics, and triggers alerts when free memory drops below a configurable threshold.

---

## 📋 Table of Contents
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Configuration](#configuration)
- [Usage](#usage)
- [Output](#output)
- [Automating with Cron](#automating-with-cron)
- [Log Files](#log-files)
- [Extending Alerts](#extending-alerts)

---

## ✨ Features
- Displays **Total**, **Used**, and **Available** RAM in MB with percentages
- Shows **Swap** usage
- Logs all stats to a structured log file
- Separate **alert log** for critical events
- Lists **Top 5 memory-consuming processes**
- Configurable **threshold** (default: 20% free)
- Easy to extend with email / Slack notifications

---

## 🔧 Prerequisites

| Tool | Purpose |
|------|---------|
| `bash` | Script interpreter |
| `free` | Read RAM statistics (`procps` package) |
| `awk`, `ps` | Data parsing and process listing |

Install if missing:
```bash
sudo apt install procps   # Debian/Ubuntu
sudo yum install procps   # RHEL/CentOS
```

---

## ⚙️ Configuration

Open `monitor_ram.sh` and edit the top section:

```bash
THRESHOLD=20                        # Alert if free RAM drops below this %
LOG_FILE="/var/log/ram_monitor.log" # Main log file
ALERT_LOG="/var/log/ram_alerts.log" # Alerts-only log file
```

---

## 🚀 Usage

**Make the script executable:**
```bash
chmod +x monitor_ram.sh
```

**Run the script:**
```bash
./monitor_ram.sh
# or with sudo for writing to /var/log
sudo ./monitor_ram.sh
```

---

## 📊 Output

```
==============================================
       RAM Monitor — Host: my-server
       Date : 2025-06-09 14:30:00
==============================================

  Total RAM:           7823 MB
  Used RAM:            4210 MB  (53.82%)
  Available RAM:       3180 MB  (40.65%)
  Swap Total:          2048 MB
  Swap Used:           512 MB

  ✅  RAM is healthy. Free: 40.65%  |  Threshold: 20%

==============================================

  Top 5 Memory-Consuming Processes:
  ----------------------------------
  root     1234   12.5% /usr/bin/java
  www-data 5678   8.3%  nginx
  ...
```

---

## ⏰ Automating with Cron

Run every 5 minutes:
```bash
crontab -e
```
Add:
```cron
*/5 * * * * /path/to/monitor_ram.sh >> /var/log/ram_monitor.log 2>&1
```

---

## 📁 Log Files

| File | Contents |
|------|---------|
| `/var/log/ram_monitor.log` | Full timestamped log of every check |
| `/var/log/ram_alerts.log` | Only warnings when threshold is breached |

---

## 📬 Extending Alerts

To receive email alerts, uncomment and configure the `send_notification()` function:
```bash
send_notification() {
    echo "$1" | mail -s "RAM Alert on $HOSTNAME" admin@example.com
}
```

Requires `mailutils`:
```bash
sudo apt install mailutils
```

---

## 📄 License
MIT — free to use and modify.
