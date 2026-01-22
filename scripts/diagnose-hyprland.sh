#!/usr/bin/env bash
# Diagnostic script for Hyprland login issues
# Run this from a TTY (Ctrl+Alt+F2) after a failed login attempt

echo "=== Hyprland Login Diagnostics ==="
echo "Timestamp: $(date)"
echo ""

echo "=== 1. Session Info ==="
loginctl session-status 2>&1 | head -30
echo ""

echo "=== 2. XDG Runtime Dir ==="
echo "XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-NOT SET}"
ls -la /run/user/ 2>&1
ls -la "${XDG_RUNTIME_DIR}" 2>&1 || echo "Runtime dir not accessible"
echo ""

echo "=== 3. DRI Device Permissions ==="
ls -la /dev/dri/ 2>&1
echo ""

echo "=== 4. User Groups ==="
id
echo ""

echo "=== 5. Recent Journal (SDDM) ==="
journalctl -u sddm --no-pager -n 50 --since "-5min" 2>&1
echo ""

echo "=== 6. Recent Journal (User Session) ==="
journalctl --user --no-pager -n 100 --since "-5min" 2>&1
echo ""

echo "=== 7. Hyprland Crash Reports ==="
ls -la ~/.cache/hyprland/ 2>&1
echo ""
if ls ~/.cache/hyprland/hyprlandCrashReport*.txt 2>/dev/null | head -1; then
    echo "Latest crash report:"
    cat "$(ls -t ~/.cache/hyprland/hyprlandCrashReport*.txt 2>/dev/null | head -1)" 2>&1 | tail -100
fi
echo ""

echo "=== 8. Seat Info ==="
cat /run/seatd.sock 2>&1 || echo "No seatd socket"
loginctl show-seat seat0 2>&1
echo ""

echo "=== 9. Checking Wayland Session Files ==="
ls -la /run/current-system/sw/share/wayland-sessions/ 2>&1
cat /run/current-system/sw/share/wayland-sessions/hyprland.desktop 2>&1
echo ""

echo "=== 10. SDDM Config ==="
cat /etc/sddm.conf 2>&1
echo ""

echo "=== Diagnostics Complete ==="
