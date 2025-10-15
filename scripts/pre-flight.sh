#!/usr/bin/env bash
# scripts/pre-flight.sh
# Usage: ./scripts/pre-flight.sh cortex 192.168.1.7 jarvis

set -euo pipefail

HOST=$1
IP=$2
USER=$3

echo "🔍 Pre-flight checks for $HOST ($IP)..."
echo ""

# Check 1: Network reachability
echo -n "  [1/6] Network reachability... "
if ping -c 3 -W 2 $IP > /dev/null 2>&1; then
  echo "✅"
else
  echo "❌ FAIL: Host unreachable"
  exit 1
fi

# Check 2: SSH connectivity
echo -n "  [2/6] SSH connectivity... "
if timeout 5 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $USER@$IP "echo 'OK'" > /dev/null 2>&1; then
  echo "✅"
else
  echo "❌ FAIL: SSH connection failed"
  echo "    Check: SSH daemon running? Correct user/key?"
  exit 1
fi

# Check 3: NixOS system
echo -n "  [3/6] NixOS system check... "
if ssh $USER@$IP "[ -f /etc/NIXOS ]" 2>/dev/null; then
  echo "✅"
else
  echo "❌ FAIL: Not a NixOS system"
  exit 1
fi

# Check 4: Disk space
echo -n "  [4/6] Disk space... "
DISK_USAGE=$(ssh $USER@$IP "df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null)
if [ $DISK_USAGE -lt 90 ]; then
  echo "✅ (${DISK_USAGE}% used)"
else
  echo "⚠️  WARN: Disk usage at ${DISK_USAGE}%"
  echo "    Consider cleaning up before deploy"
fi

# Check 5: Critical services
echo -n "  [5/6] Critical services... "
FAILED_SERVICES=0
for svc in sshd NetworkManager; do
  if ! ssh $USER@$IP "systemctl is-active $svc" > /dev/null 2>&1; then
    echo ""
    echo "    ❌ $svc is not active"
    FAILED_SERVICES=1
  fi
done
if [ $FAILED_SERVICES -eq 0 ]; then
  echo "✅"
else
  exit 1
fi

# Check 6: System load
echo -n "  [6/6] System load... "
LOAD=$(ssh $USER@$IP "uptime | awk -F'load average:' '{print \$2}' | awk '{print \$1}' | sed 's/,//'" 2>/dev/null)
echo "✅ (load: $LOAD)"

echo ""
echo "✅ All pre-flight checks passed!"
echo "   Ready to deploy to $HOST"
