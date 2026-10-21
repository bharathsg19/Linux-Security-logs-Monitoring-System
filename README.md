# Linux Security Log Monitoring

## 1. Project Overview

This project demonstrates how to monitor Linux authentication logs for common SSH login events, including failed login attempts, invalid usernames, and successful logins. A Bash script collects recent SSH service logs and creates a simple text report.

**Environment:** Ubuntu Linux running in a virtual machine (for example, VirtualBox)

## 2. Project Objectives

- Locate and review Linux authentication logs.
- Identify failed SSH login attempts and invalid usernames.
- Summarize SSH authentication activity.
- Generate a reusable security report with Bash.
- Practise basic security monitoring and incident-triage skills.

## 3. Prerequisites

- Ubuntu Linux with `systemd` and `journalctl`.
- A user account with `sudo` privileges.
- OpenSSH server installed if you want to test SSH events.
- Basic knowledge of `grep`, `awk`, `sort`, and `uniq`.

> **Safety:** Run these checks only on systems you own or are authorized to administer. Do not attempt logins against third-party systems.

## 4. Check SSH and View Logs

Check the SSH service:

```bash
systemctl status ssh
```

If SSH is not installed and you need it for your lab:

```bash
sudo apt update
sudo apt install openssh-server
sudo systemctl enable --now ssh
```

View recent SSH logs:

```bash
sudo journalctl -u ssh --since "24 hours ago"
```

Some Ubuntu installations also record authentication events in `/var/log/auth.log`:

```bash
sudo grep -Ei 'Failed password|Invalid user|Accepted password|Accepted publickey' /var/log/auth.log
```

If that file does not exist, use `journalctl`.

## 5. Quick Log Checks

Failed password attempts:

```bash
sudo journalctl -u ssh --since "24 hours ago" | grep -i "Failed password"
```

Invalid-user attempts:

```bash
sudo journalctl -u ssh --since "24 hours ago" | grep -i "Invalid user"
```

Successful SSH authentication:

```bash
sudo journalctl -u ssh --since "24 hours ago" | grep -Ei "Accepted password|Accepted publickey"
```

Count failed-password events:

```bash
sudo journalctl -u ssh --since "24 hours ago" | grep -ic "Failed password"
```

Log formats differ by distribution and configuration, so review the actual output before relying on a search pattern.

## 6. Create the Monitoring Script

Create a project directory:

```bash
mkdir -p ~/linux-security-log-monitor/logs
cd ~/linux-security-log-monitor
nano security_log_monitor.sh
```

Paste this script:

```bash
#!/usr/bin/env bash
set -u

SINCE="${1:-24 hours ago}"
PROJECT_DIR="${HOME}/linux-security-log-monitor"
LOG_DIR="${PROJECT_DIR}/logs"
REPORT="${LOG_DIR}/security_report.txt"

mkdir -p "$LOG_DIR"

if ! command -v journalctl >/dev/null 2>&1; then
    echo "Error: journalctl was not found; this script requires systemd journal logs." >&2
    exit 1
fi

if ! sudo -v; then
    echo "Error: sudo authorization is required to read SSH logs." >&2
    exit 1
fi

TMP_LOG="$(mktemp)"
trap 'rm -f "$TMP_LOG"' EXIT

if ! sudo journalctl -u ssh --since "$SINCE" --no-pager > "$TMP_LOG"; then
    echo "Error: unable to read SSH logs. Check the service name and permissions." >&2
    exit 1
fi

FAILED_COUNT="$(grep -ic 'Failed password' "$TMP_LOG" || true)"
INVALID_COUNT="$(grep -ic 'Invalid user' "$TMP_LOG" || true)"
SUCCESS_COUNT="$(grep -Eic 'Accepted password|Accepted publickey' "$TMP_LOG" || true)"

{
    echo "Linux Security Log Monitoring Report"
    echo "Generated: $(date)"
    echo "Period: $SINCE"
    echo "Host: $(hostname)"
    echo
    echo "Summary"
    echo "-------"
    echo "Failed password events: $FAILED_COUNT"
    echo "Invalid-user events:    $INVALID_COUNT"
    echo "Successful SSH events:  $SUCCESS_COUNT"
    echo
    echo "Failed password events"
    echo "----------------------"
    grep -i 'Failed password' "$TMP_LOG" || echo "None found."
    echo
    echo "Invalid-user events"
    echo "-------------------"
    grep -i 'Invalid user' "$TMP_LOG" || echo "None found."
    echo
    echo "Successful SSH events"
    echo "---------------------"
    grep -Ei 'Accepted password|Accepted publickey' "$TMP_LOG" || echo "None found."
} > "$REPORT"

chmod 600 "$REPORT"
echo "Report saved to: $REPORT"
```

Save the file and make the script executable:

```bash
chmod +x security_log_monitor.sh
```

Run it:

```bash
./security_log_monitor.sh
```

Or specify a shorter period:

```bash
./security_log_monitor.sh "2 hours ago"
```

The script uses `sudo` to read the journal and saves the report with owner-only permissions.

## 7. Review the Report

```bash
cat ~/linux-security-log-monitor/logs/security_report.txt
```

The report summarizes failed passwords, invalid usernames, and successful SSH authentication events. This is a basic learning tool, not a full intrusion-detection system.

## 8. Test in Your Own Lab

If SSH is running on your own Ubuntu VM, generate a controlled failed-login event using a deliberately nonexistent username:

```bash
ssh invalid-lab-user@127.0.0.1
```

Then rerun the script and inspect the report. Depending on the system configuration, logs may use the service name `ssh` or `sshd`.

Do not weaken SSH settings solely to make the test work.

## 9. Troubleshooting

- **No output:** There may be no matching events in the selected time period.
- **No `/var/log/auth.log`:** Use `journalctl`; not all systems keep a separate authentication log.
- **No SSH logs:** Check `systemctl status ssh` and verify the service name. Some systems use `sshd`.
- **Permission denied:** Confirm your account can use `sudo`.
- **No matching events:** Compare the script's search patterns with the actual log messages on your system.

## 10. Skills Demonstrated

- Linux command-line administration
- SSH and authentication log analysis
- Bash scripting
- Basic security-event triage
- Text filtering and report generation
- Troubleshooting

## 11. Suggested GitHub Repository Structure

```text
linux-security-log-monitor/
├── README.md
├── security_log_monitor.sh
└── logs/
    └── .gitkeep
```

Do not commit real authentication logs, IP addresses, usernames, hostnames, tokens, or other sensitive system information. Keep generated reports local unless reviewed and sanitized.

## 12. Future Improvements

- Add counts for source IP addresses and targeted usernames based on your system's log format.
- Support both `ssh` and `sshd` service names.
- Flag unusually high failed-login volumes using configurable thresholds.
- Add alerts through an approved notification method.
- Add tests using sanitized sample log files.

## 13. Disclaimer

This project is for education and authorized system administration. Pattern-based monitoring may miss events or produce inaccurate counts when log formats differ. Use established monitoring tools and your organization's incident-response process in production.
