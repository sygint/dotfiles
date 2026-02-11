#!/usr/bin/env bash
# scripts/safe-deploy.sh
# Usage: ./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis

set -euo pipefail

HOST=$1
IP=$2
USER=$3

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 Safe deployment to $HOST"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 1: Pre-flight checks
echo "Step 1: Pre-flight validation"
if ! $SCRIPT_DIR/pre-flight.sh $HOST $IP $USER; then
  echo ""
  echo "❌ Pre-flight checks failed!"
  echo "   Aborting deployment."
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 2: Deploy
echo "Step 2: Deploying with fleet push"
echo ""

# Record current generation before deploy
BEFORE_GEN=$(ssh $USER@$IP "readlink /nix/var/nix/profiles/system" 2>/dev/null | sed -n 's/system-\([0-9]*\)-link/\1/p' || echo "unknown")
echo "Current generation: $BEFORE_GEN"
echo ""

# Run fleet push
if fleet push $HOST; then
  echo ""
  echo "✅ Deploy command completed"
else
  echo ""
  echo "❌ Deploy command failed!"
  echo "   System may be in inconsistent state"
  echo "   Check manually: ssh $USER@$IP"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 3: Validate
echo "Step 3: Post-deployment validation"
if ! $SCRIPT_DIR/validate.sh $HOST $IP $USER; then
  echo ""
  echo "⚠️  Validation failed!"
  echo ""
  echo "Rollback instructions:"
  echo "  1. SSH into host: ssh $USER@$IP"
  echo "  2. Check current generation: readlink /run/current-system"
  echo "  3. List available generations: sudo nix-env -p /nix/var/nix/profiles/system --list-generations"
  echo "  4. Rollback: sudo nixos-rebuild switch --rollback"
  echo "  5. Or switch to specific generation: sudo nix-env -p /nix/var/nix/profiles/system --switch-generation <number>"
  exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

AFTER_GEN=$(ssh $USER@$IP "readlink /nix/var/nix/profiles/system" 2>/dev/null | sed -n 's/system-\([0-9]*\)-link/\1/p' || echo "unknown")
echo "🎉 Deployment successful!"
echo "   $HOST: generation $BEFORE_GEN → $AFTER_GEN"
echo ""
