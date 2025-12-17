#!/bin/ash
# File exists as /root/cleanup_vouchers.sh
# cron schedule for running every month 0 3 1 * * /root/cleanup_vouchers.sh

# Simple version for OpenWrt ash
INPUT_FILE="/mnt/sda1/ndslog/vouchers.txt"
TEMP_FILE="/tmp/vouchers_temp.$$"
cutoff_time=$(($(date +%s) - 2678400))

# Backup
cp "$INPUT_FILE" "${INPUT_FILE}.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null

# Delete vouchers_backup files older than 100 days
find "/mnt/sda1/ndslog" -name "vouchers.txt.backup*" -type f -mtime +100 -delete 2>/dev/null

# Process with awk if available, otherwise use shell loop
if command -v awk >/dev/null 2>&1; then
    awk -F',' -v cutoff="$cutoff_time" '
    $7 ~ /^[0-9]+$/ && $7 > 0 && $7 < cutoff { next }
    { print }
    ' "$INPUT_FILE" > "$TEMP_FILE"
else
    # Fallback to shell loop
    while IFS= read -r line; do
        epoch_time=$(echo "$line" | cut -d',' -f7)
        case "$epoch_time" in
            ''|*[!0-9]*) echo "$line" ;;
            *) [ "$epoch_time" -le 0 ] || [ "$epoch_time" -ge "$cutoff_time" ] && echo "$line" ;;
        esac
    done < "$INPUT_FILE" > "$TEMP_FILE"
fi

# Replace if temp file exists and has content
if [ -s "$TEMP_FILE" ]; then
    mv "$TEMP_FILE" "$INPUT_FILE"
    echo "Cleanup completed"
else
    echo "Error: No output generated" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi
