#!/bin/bash

#Description: Monitors available RAM and logs/alerts when

# ─── CONFIGURATION ────────────────────────────────────────────
THRESHOLD=20                          # Alert if free RAM drops below this %
LOG_FILE="/var/log/ram_monitor.log"   # Log file path
ALERT_LOG="/var/log/ram_alerts.log"   # Separate file for alerts only
DATE=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# ─── FUNCTIONS ────────────────────────────────────────────────

log_info() {
    echo "[$DATE] [INFO]  $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo "[$DATE] [WARN]  $1" | tee -a "$LOG_FILE" | tee -a "$ALERT_LOG"
}

log_error() {
    echo "[$DATE] [ERROR] $1" | tee -a "$LOG_FILE"
}

get_ram_stats() {
    TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
    USED_RAM=$(free -m  | awk '/^Mem:/{print $3}')
    FREE_RAM=$(free -m  | awk '/^Mem:/{print $4}')
    AVAIL_RAM=$(free -m | awk '/^Mem:/{print $7}')
    SWAP_TOTAL=$(free -m | awk '/^Swap:/{print $2}')
    SWAP_USED=$(free -m  | awk '/^Swap:/{print $3}')

    if [ "$TOTAL_RAM" -eq 0 ]; then
        log_error "Unable to read RAM stats. Exiting."
        exit 1
    fi

    FREE_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($AVAIL_RAM/$TOTAL_RAM)*100}")
    USED_PERCENT=$(awk "BEGIN {printf \"%.2f\", ($USED_RAM/$TOTAL_RAM)*100}")
}

print_banner() {
    echo "=============================================="
    echo "       RAM Monitor — Host: $HOSTNAME"
    echo "       Date : $DATE"
    echo "=============================================="
}

send_notification() {
    # ── Extend this block to send emails / Slack / etc. ──────
    # Example (requires mailutils): 
    # echo "$1" | mail -s "RAM Alert on $HOSTNAME" admin@example.com
    log_warn "NOTIFICATION: $1"
}

check_ram() {
    get_ram_stats
    print_banner

    echo ""
    printf "  %-20s %s\n" "Total RAM:"     "${TOTAL_RAM} MB"
    printf "  %-20s %s\n" "Used RAM:"      "${USED_RAM} MB  (${USED_PERCENT}%)"
    printf "  %-20s %s\n" "Available RAM:" "${AVAIL_RAM} MB  (${FREE_PERCENT}%)"
    printf "  %-20s %s\n" "Swap Total:"    "${SWAP_TOTAL} MB"
    printf "  %-20s %s\n" "Swap Used:"     "${SWAP_USED} MB"
    echo ""

    log_info "Total: ${TOTAL_RAM}MB | Used: ${USED_RAM}MB (${USED_PERCENT}%) | Available: ${AVAIL_RAM}MB (${FREE_PERCENT}%)"

    # ── Threshold Check ──────────────────────────────────────
    BELOW_THRESHOLD=$(awk "BEGIN {print ($FREE_PERCENT < $THRESHOLD) ? 1 : 0}")

    if [ "$BELOW_THRESHOLD" -eq 1 ]; then
        echo " WARNING: Available RAM is critically low!"
        echo "      Free: ${FREE_PERCENT}%  |  Threshold: ${THRESHOLD}%"
        echo ""
        send_notification "Available RAM on $HOSTNAME is only ${FREE_PERCENT}% (threshold: ${THRESHOLD}%)"
    else
        echo "  RAM is healthy. Free: ${FREE_PERCENT}%  |  Threshold: ${THRESHOLD}%"
        echo ""
        log_info "RAM is OK. Free: ${FREE_PERCENT}%"
    fi

    echo "=============================================="
}

# ─── TOP MEMORY CONSUMERS ─────────────────────────────────────
show_top_consumers() {
    echo ""
    echo "  Top 5 Memory-Consuming Processes:"
    echo "  ----------------------------------"
    ps aux --sort=-%mem | awk 'NR==1{print "  "$0} NR>1 && NR<=6{printf "  %-8s %-6s %-6s %s\n", $1, $2, $4"%", $11}'
    echo ""
}

# ─── MAIN ─────────────────────────────────────────────────────
main() {
    # Ensure log directory exists
    mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null

    check_ram
    show_top_consumers

    log_info "RAM check completed."
}

main
