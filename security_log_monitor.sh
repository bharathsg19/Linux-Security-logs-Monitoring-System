#!/bin/bash

set -u

PROJECT_DIR="/home/bharath/linux-security-log-monitor"
REPORT="$PROJECT_DIR/logs/security_report.txt"
SINCE="${1:-24 hours ago}"

mkdir -p "$PROJECT_DIR/logs"

if ! command -v journalctl >/dev/null 2>&1; then
    echo "Error: journalctl is not installed." >&2
    exit 1
fi

if ! sudo -v; then
    echo "Error: administrative access is required to read these logs." >&2
    exit 1
fi

{
    echo "========================================"
    echo "Linux Security Log Monitoring Report"
    echo "Generated: $(date)"
    echo "Period: $SINCE"
    echo "========================================"
    echo

    echo "----- Failed SSH Authentication Events -----"

    sudo journalctl -u ssh --since "$SINCE" --no-pager 2>/dev/null |
        grep -Ei 'Failed password|authentication failure|Invalid user' ||
        echo "No matching SSH authentication failures found."

    echo
    echo "----- Failed Password Attempts by Source IP -----"

    sudo journalctl -u ssh --since "$SINCE" --no-pager 2>/dev/null |
        grep 'Failed password' |
        awk '{for (i=1; i<=NF; i++) if ($i=="from") print $(i+1)}' |
        sort |
        uniq -c |
        sort -nr

    echo
    echo "----- Invalid User Attempts -----"

    sudo journalctl -u ssh --since "$SINCE" --no-pager 2>/dev/null |
        grep 'Invalid user' ||
        echo "No invalid-user events found."

    echo
    echo "----- Recent SSH Service Errors -----"

    sudo journalctl -u ssh -p err --since "$SINCE" --no-pager 2>/dev/null ||
        echo "No matching SSH service errors found."

    echo
    echo "----- Report Complete -----"

} > "$REPORT"

echo "Security report generated: $REPORT"
