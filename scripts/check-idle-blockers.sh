#!/usr/bin/env bash
# Diagnostic script to check what might be blocking hypridle from triggering
# Usage: ./check-idle-blockers.sh

set -euo pipefail

# Colors for output
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

# Function to check if session is locked
is_session_locked() {
    pidof hyprlock > /dev/null 2>&1
}

# Function to check if a process is running
check_process() {
    local process_name="$1"
    local display_name="${2:-$process_name}"
    
    if pgrep -x "$process_name" > /dev/null 2>&1; then
        local count
        count=$(pgrep -x "$process_name" | wc -l)
        echo -e "   ${YELLOW}⚠${NC}  $display_name running ($count processes)"
    else
        echo -e "   ${GREEN}✓${NC}  $display_name not running"
    fi
}

# Main diagnostic output
main() {
    echo "=== Hypridle Idle Blocker Diagnostic ==="
    echo ""

    # 1. SystemD Inhibitors
    echo "1. SystemD Inhibitors (sleep/idle):"
    systemd-inhibit --list 2>/dev/null || echo "   No inhibitors found"
    echo ""

    # 2. Processes that might prevent idle
    echo "2. Processes that might prevent idle:"
    echo ""
    echo "   Browsers:"
    check_process "firefox" "Firefox"
    check_process "chrome" "Chrome"
    check_process "brave" "Brave"
    echo ""

    echo "   Media players:"
    check_process "mpv" "MPV"
    check_process "vlc" "VLC"
    check_process "spotify" "Spotify"
    echo ""

    echo "   Communication apps:"
    check_process "discord" "Discord"
    check_process "slack" "Slack"
    check_process "teams" "Teams"
    echo ""

    # 3. Hypridle service status
    echo "3. Hypridle service status:"
    if systemctl --user is-active --quiet hypridle.service; then
        echo -e "   ${GREEN}✓${NC} Service is active"
    else
        echo -e "   ${RED}✗${NC} Service is NOT active"
    fi
    
    echo ""
    echo "   Recent logs:"
    journalctl --user -u hypridle.service --since "5 minutes ago" --no-pager 2>/dev/null | tail -10 || echo "   No recent logs"
    echo ""

    # 4. Lock state
    echo "4. Current lock state:"
    if is_session_locked; then
        echo -e "   ${GREEN}✓${NC} Screen is LOCKED - monitors WILL turn off after 10min idle"
    else
        echo -e "   ${YELLOW}⚠${NC}  Screen is UNLOCKED - monitors will NOT turn off (by design)"
    fi
    echo ""

    # 5. DPMS lock check logs
    echo "5. Recent DPMS lock-aware activity:"
    journalctl -t "dpms-lock-aware" --since "10 minutes ago" --no-pager 2>/dev/null | tail -5 || echo "   No recent activity"
    echo ""

    # Configuration summary
    echo "=== Current Configuration ==="
    echo "Your system uses lock-aware DPMS control:"
    echo ""
    echo "  • Monitors only turn off when screen is locked"
    echo "  • Browser wake locks are ignored for DPMS (but respected for suspend)"
    echo "  • You can work/watch videos without screen turning off"
    echo "  • When locked, monitors turn off after 10min of inactivity"
    echo ""
    echo "=== Timeline ==="
    echo "  2.5 min  → Screen dims to 10%"
    echo "  5 min    → Screen locks (hyprlock)"
    echo "  10 min   → Monitors turn off (if locked)"
    echo "  20 min   → System suspends"
    echo ""
    echo "=== Before Bed ==="
    echo "Lock your screen (Super+L) and monitors will turn off automatically."
    echo "Browsers can stay open with all tabs!"
}

main "$@"
