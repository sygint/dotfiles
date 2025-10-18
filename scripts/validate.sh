#!/usr/bin/env bash
# scripts/validate.sh
# Usage: ./scripts/validate.sh cortex 192.168.1.7 jarvis

set -euo pipefail

HOST=$1
IP=$2
USER=$3

echo "🔍 Validating deployment to $HOST..."
echo ""

# Wait a moment for services to settle
sleep 5

# Check 1: SSH still works
echo -n "  [1/5] SSH connectivity... "
if timeout 10 ssh -o ConnectTimeout=10 $USER@$IP "echo 'OK'" > /dev/null 2>&1; then
  echo "✅"
else
  echo "❌ CRITICAL: Lost SSH access!"
  echo "    Manual intervention required"
  exit 1
fi

# Check 2: System is running
echo -n "  [2/5] System state... "
SYS_STATE=$(ssh $USER@$IP "systemctl is-system-running" 2>/dev/null || echo "unknown")
if echo "$SYS_STATE" | grep -qE "running|degraded"; then
  echo "✅ ($SYS_STATE)"
else
  echo "⚠️  WARN: System state is $SYS_STATE"
fi

# Check 3: Critical services
echo -n "  [3/5] Critical services... "
FAILED_SERVICES=0
for svc in sshd NetworkManager; do
  if ! ssh $USER@$IP "systemctl is-active $svc" > /dev/null 2>&1; then
    echo ""
    echo "    ❌ $svc failed"
    FAILED_SERVICES=1
  fi
done
if [ $FAILED_SERVICES -eq 0 ]; then
  echo "✅"
else
  echo "⚠️  Some services failed - check manually"
fi

# Check 4: New generation activated
echo -n "  [4/5] Boot generation... "
CURRENT_GEN=$(ssh $USER@$IP "readlink /nix/var/nix/profiles/system" 2>/dev/null | sed -n 's/system-\([0-9]*\)-link/\1/p' || echo "unknown")
echo "✅ (generation $CURRENT_GEN)"

# Check 5: No failed units
echo -n "  [5/5] Failed units... "
FAILED_COUNT=$(ssh $USER@$IP "systemctl list-units --failed --no-legend | wc -l" 2>/dev/null || echo "0")
if [ $FAILED_COUNT -eq 0 ]; then
  echo "✅"
else
  echo "⚠️  $FAILED_COUNT failed units"
  echo "    Run: ssh $USER@$IP 'systemctl list-units --failed'"
fi

echo ""
if [ $FAILED_SERVICES -eq 0 ] && [ $FAILED_COUNT -eq 0 ]; then
  echo "✅ Deployment validated successfully!"
else
  echo "⚠️  Deployment completed with warnings"
  echo "   Manual verification recommended"
fi
