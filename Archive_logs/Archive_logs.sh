#!/bin/bash
# =============================================================
#  Project   : Archiving Older Log Files Automatically 
#  Description: Finds log files older than a defined number of
#               days, compresses them into a dated archive, and
#               optionally removes the originals.
# =============================================================

# ─── CONFIGURATION ────────────────────────────────────────────
LOG_SOURCE_DIR="/var/log"                   # Directory to scan for old logs
ARCHIVE_BASE_DIR="/var/log/archives"        # Where archives will be stored
DAYS_OLD=30                                 # Archive files older than N days
LOG_EXTENSIONS=("*.log" "*.log.[0-9]*")     # File patterns to match
MAX_ARCHIVE_AGE=90                          # Delete archives older than N days
DELETE_AFTER_ARCHIVE=true                   # Remove originals after archiving
DRY_RUN=false                               # true = preview only, no changes
SCRIPT_LOG="/var/log/archive_manager.log"   # This script's own log file
DATE=$(date '+%Y-%m-%d')
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
HOSTNAME=$(hostname)

# ─── COLORS ───────────────────────────────────────────────────
RED='\033[0;31m'; YELLOW='\033[1;33m'
GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'

# ─── FUNCTIONS ────────────────────────────────────────────────

log_info()    { echo -e "${GREEN}[INFO]${NC}  [$DATE] $1" | tee -a "$SCRIPT_LOG"; }
log_warn()    { echo -e "${YELLOW}[WARN]${NC}  [$DATE] $1" | tee -a "$SCRIPT_LOG"; }
log_error()   { echo -e "${RED}[ERROR]${NC} [$DATE] $1" | tee -a "$SCRIPT_LOG"; }
log_dry_run() { echo -e "${CYAN}[DRY-RUN]${NC} $1" | tee -a "$SCRIPT_LOG"; }

print_banner() {
    echo ""
    echo "=================================================="
    echo "    Log Archiver — Host: $HOSTNAME"
    echo "    Date         : $DATE"
    echo "    Source Dir   : $LOG_SOURCE_DIR"
    echo "    Archive Dir  : $ARCHIVE_BASE_DIR"
    echo "    Archive files older than : ${DAYS_OLD} days"
    echo "    Delete after archive     : $DELETE_AFTER_ARCHIVE"
    echo "    Dry run mode             : $DRY_RUN"
    echo "=================================================="
    echo ""
}

check_dependencies() {
    for CMD in find tar gzip du; do
        if ! command -v "$CMD" &>/dev/null; then
            log_error "Required command not found: $CMD"
            exit 1
        fi
    done
}

validate_directories() {
    if [ ! -d "$LOG_SOURCE_DIR" ]; then
        log_error "Source directory does not exist: $LOG_SOURCE_DIR"
        exit 1
    fi

    if $DRY_RUN; then
        log_dry_run "Would create archive directory: $ARCHIVE_BASE_DIR"
    else
        mkdir -p "$ARCHIVE_BASE_DIR" || {
            log_error "Failed to create archive directory: $ARCHIVE_BASE_DIR"
            exit 1
        }
    fi
}

collect_old_log_files() {
    OLD_FILES=()

    for PATTERN in "${LOG_EXTENSIONS[@]}"; do
        while IFS= read -r -d '' FILE; do
            OLD_FILES+=("$FILE")
        done < <(find "$LOG_SOURCE_DIR" -maxdepth 2 \
            -name "$PATTERN" \
            -mtime +"$DAYS_OLD" \
            -type f \
            -print0 2>/dev/null)
    done

    # Remove duplicates
    IFS=$'\n' OLD_FILES=($(printf '%s\n' "${OLD_FILES[@]}" | sort -u))
    unset IFS
}

create_archive() {
    local FILE_COUNT=${#OLD_FILES[@]}

    if [ "$FILE_COUNT" -eq 0 ]; then
        log_info "No log files older than ${DAYS_OLD} days found. Nothing to archive."
        echo ""
        echo "  Nothing to archive."
        return 0
    fi

    echo "  Found ${FILE_COUNT} file(s) to archive:"
    echo ""
    for FILE in "${OLD_FILES[@]}"; do
        FILE_SIZE=$(du -sh "$FILE" 2>/dev/null | awk '{print $1}')
        FILE_DATE=$(stat -c '%y' "$FILE" 2>/dev/null | cut -d' ' -f1)
        printf "     %-55s %6s  (%s)\n" "$FILE" "$FILE_SIZE" "$FILE_DATE"
    done
    echo ""

    ARCHIVE_NAME="logs_${DATE}_${TIMESTAMP}.tar.gz"
    ARCHIVE_PATH="$ARCHIVE_BASE_DIR/$ARCHIVE_NAME"

    if $DRY_RUN; then
        log_dry_run "Would create archive: $ARCHIVE_PATH"
        log_dry_run "Would include ${FILE_COUNT} files"
        [ "$DELETE_AFTER_ARCHIVE" = true ] && \
            log_dry_run "Would delete original ${FILE_COUNT} files after archiving"
        return 0
    fi

    echo " Creating archive: $ARCHIVE_PATH"
    log_info "Creating archive: $ARCHIVE_PATH (${FILE_COUNT} files)"

    # Create the tar.gz archive
    if tar -czf "$ARCHIVE_PATH" "${OLD_FILES[@]}" 2>/dev/null; then
        ARCHIVE_SIZE=$(du -sh "$ARCHIVE_PATH" | awk '{print $1}')
        echo " Archive created successfully! Size: $ARCHIVE_SIZE"
        log_info "Archive created: $ARCHIVE_PATH (Size: $ARCHIVE_SIZE)"

        # Optionally delete original files
        if [ "$DELETE_AFTER_ARCHIVE" = true ]; then
            echo ""
            echo "  Removing original log files..."
            local REMOVED=0
            for FILE in "${OLD_FILES[@]}"; do
                if rm -f "$FILE"; then
                    REMOVED=$((REMOVED + 1))
                    log_info "Deleted: $FILE"
                else
                    log_warn "Could not delete: $FILE"
                fi
            done
            echo " Removed $REMOVED original file(s)."
        fi

    else
        log_error "Failed to create archive: $ARCHIVE_PATH"
        rm -f "$ARCHIVE_PATH"  # Cleanup partial archive
        exit 1
    fi
}

cleanup_old_archives() {
    echo ""
    echo " Checking for archives older than ${MAX_ARCHIVE_AGE} days..."

    OLD_ARCHIVES=$(find "$ARCHIVE_BASE_DIR" -name "*.tar.gz" \
        -mtime +"$MAX_ARCHIVE_AGE" -type f 2>/dev/null)

    if [ -z "$OLD_ARCHIVES" ]; then
        echo " No old archives to clean up."
        return
    fi

    echo "  Removing old archives:"
    while IFS= read -r ARCH; do
        if $DRY_RUN; then
            log_dry_run "Would delete old archive: $ARCH"
        else
            rm -f "$ARCH"
            log_info "Deleted old archive: $ARCH"
            echo "     Deleted: $ARCH"
        fi
    done <<< "$OLD_ARCHIVES"
}

print_summary() {
    echo ""
    echo "=================================================="
    echo "   Archive Summary"
    echo "  ------------------"
    TOTAL_ARCHIVES=$(find "$ARCHIVE_BASE_DIR" -name "*.tar.gz" 2>/dev/null | wc -l)
    ARCHIVE_DIR_SIZE=$(du -sh "$ARCHIVE_BASE_DIR" 2>/dev/null | awk '{print $1}')
    echo "  Total archives stored : $TOTAL_ARCHIVES"
    echo "  Archive directory size: $ARCHIVE_DIR_SIZE"
    echo "  Archive location      : $ARCHIVE_BASE_DIR"
    echo "=================================================="
    echo ""
}

# ─── ARGUMENT HANDLING ────────────────────────────────────────
for ARG in "$@"; do
    case "$ARG" in
        --dry-run) DRY_RUN=true ;;
        --help)
            echo "Usage: $0 [--dry-run] [--help]"
            echo "  --dry-run   Preview what would happen without making changes"
            echo "  --help      Show this help message"
            exit 0
            ;;
        *) log_warn "Unknown argument: $ARG" ;;
    esac
done

# ─── MAIN ─────────────────────────────────────────────────────
main() {
    mkdir -p "$(dirname "$SCRIPT_LOG")" 2>/dev/null
    print_banner
    check_dependencies
    validate_directories
    collect_old_log_files
    create_archive
    cleanup_old_archives
    print_summary
    log_info "Archiving process completed."
}

main
