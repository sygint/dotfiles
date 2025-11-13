# justfile - Task automation for NixOS config
# Run `just` to see all commands

# Default: show available commands
default:
  @just --list

# ====== PRE/POST HOOKS (EmergentMind Pattern) ======

# Run BEFORE every rebuild/deploy - syncs secrets automatically
rebuild-pre: update-secrets
 # Show system information
info:
  @echo "📦 NixOS Configuration Info"
  @echo ""
  @echo "🖥️  Hostname: $(hostname)"
  @echo "🔢 Current Generation: $(nixos-rebuild list-generations 2>&1 | grep current | head -1 | cut -d' ' -f1 || echo 'N/A')"
  @echo "📁 Config: $(pwd)"
  @echo ""
  @echo "🌐 Known Hosts:"
  @nix-instantiate --eval --strict --json -E "builtins.attrNames (import ./fleet-config.nix).hosts" 2>/dev/null | jq -r '.[]' | sed 's/^/  - /' || echo "  (Unable to load)"
  @echo ""
  @echo "🔐 Secrets: $(test -d ../nixos-secrets && echo '✅ Available' || echo '❌ Not found')"

# Run AFTER rebuild - validate sops is working
rebuild-post:
  @echo "✅ Rebuild complete"
  @systemctl --user is-active sops-nix.service > /dev/null && echo "✅ sops-nix active" || echo "⚠️  sops-nix check manually"

# Sync secrets from separate repo (HYBRID APPROACH)
update-secrets:
  @echo "🔄 Syncing secrets..."
  @cd ../nixos-secrets && git pull || true
  @nix flake update nixos-secrets --timeout 5
  @echo "✅ Secrets synced"

# ====== GENERIC BUILD/DEPLOY COMMANDS ======

# Build any host configuration locally (no deploy)
build HOST: rebuild-pre
  @echo "🔨 Building {{HOST}}..."
  nix build .#nixosConfigurations.{{HOST}}.config.system.build.toplevel --show-trace
  @echo "✅ Build successful for {{HOST}}"

# Deploy to ANY remote host (with safety checks)
deploy HOST: rebuild-pre
  #!/usr/bin/env bash
  set -euo pipefail
  
  # Auto-detect IP and user from fleet-config.nix
  IP=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ip" 2>/dev/null | tr -d '"' || echo "")
  USER=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ssh.user" 2>/dev/null | tr -d '"' || echo "syg")
  
  if [ -z "$IP" ] || [ "$IP" = "unknown" ]; then
    echo "❌ Could not determine IP for {{HOST}}"
    echo "💡 Tip: Check fleet-config.nix or use: just deploy-manual {{HOST}} <IP> <USER>"
    exit 1
  fi
  
  echo "🚀 Deploying to {{HOST}} ($USER@$IP)"
  ./scripts/deployment/safe-deploy.sh {{HOST}} "$IP" "$USER"

# Deploy with manual IP/user (for new hosts or overrides)
deploy-manual HOST IP USER: rebuild-pre
  @echo "🚀 Deploying to {{HOST}} ({{USER}}@{{IP}})"
  ./scripts/deployment/safe-deploy.sh {{HOST}} {{IP}} {{USER}}

# Rollback a remote host to previous generation
rollback HOST:
  #!/usr/bin/env bash
  set -euo pipefail
  IP=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ip" 2>/dev/null | tr -d '"' || echo "")
  USER=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ssh.user" 2>/dev/null | tr -d '"' || echo "syg")
  
  if [ -z "$IP" ]; then
    echo "❌ Could not determine IP for {{HOST}}"
    exit 1
  fi
  
  echo "⏮️  Rolling back {{HOST}} to previous generation..."
  ssh "$USER@$IP" 'sudo nixos-rebuild --rollback switch'
  echo "✅ Rollback complete"

# Pre-flight checks only (no deploy)
check HOST:
  #!/usr/bin/env bash
  set -euo pipefail
  IP=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ip" 2>/dev/null | tr -d '"' || echo "")
  USER=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ssh.user" 2>/dev/null | tr -d '"' || echo "syg")
  
  if [ -z "$IP" ]; then
    echo "❌ Could not determine IP for {{HOST}}"
    exit 1
  fi
  
  ./scripts/deployment/pre-flight.sh {{HOST}} "$IP" "$USER"

# Validate host (post-deploy check)
validate HOST:
  #!/usr/bin/env bash
  set -euo pipefail
  IP=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ip" 2>/dev/null | tr -d '"' || echo "")
  USER=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ssh.user" 2>/dev/null | tr -d '"' || echo "syg")
  
  if [ -z "$IP" ]; then
    echo "❌ Could not determine IP for {{HOST}}"
    exit 1
  fi
  
  ./scripts/deployment/validate.sh {{HOST}} "$IP" "$USER"

# SSH into any host
ssh HOST:
  #!/usr/bin/env bash
  set -euo pipefail
  IP=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ip" 2>/dev/null | tr -d '"' || echo "")
  USER=$(nix-instantiate --eval --strict -E "(import ./fleet-config.nix).hosts.{{HOST}}.ssh.user" 2>/dev/null | tr -d '"' || echo "syg")
  
  if [ -z "$IP" ]; then
    echo "❌ Could not determine IP for {{HOST}}"
    exit 1
  fi
  
  ssh "$USER@$IP"

# ====== LOCAL OPERATIONS ======

# Rebuild current host with pre/post hooks
rebuild: rebuild-pre && rebuild-post
  #!/usr/bin/env bash
  HOSTNAME=$(hostname)
  echo "🔨 Rebuilding $HOSTNAME..."
  sudo nixos-rebuild --flake .#"$HOSTNAME" switch

# Rebuild specific host locally (useful for testing configs)
rebuild-host HOST: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#{{HOST}} switch

# Rebuild with trace for debugging
rebuild-trace HOST: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#{{HOST}} --show-trace switch

# ====== NAMED HOST SHORTCUTS (for frequently used hosts) ======

# Quick shortcuts for your main systems
rebuild-orion: (rebuild-host "orion")
rebuild-cortex: (rebuild-host "cortex")
deploy-cortex: (deploy "cortex")
check-cortex: (check "cortex")
ssh-cortex: (ssh "cortex")

# ====== UPDATE COMMANDS ======

# Update all flake inputs
update:
  nix flake update

# Update specific input
update-input INPUT:
  nix flake update {{INPUT}}

# Update + rebuild current host
update-rebuild: update rebuild

# Update + deploy to remote host
update-deploy HOST: update (deploy HOST)

# ====== FLEET MANAGEMENT ======

# List all systems discovered from flake
fleet-list:
  @./scripts/deployment/fleet.sh list

# Fleet status (check all systems)
fleet-status:
  @./scripts/deployment/fleet.sh status

# Deploy to multiple hosts (comma-separated: orion,cortex)
fleet-deploy HOSTS:
  @./scripts/deployment/fleet.sh deploy {{HOSTS}}

# Check all hosts in fleet
fleet-check:
  #!/usr/bin/env bash
  for host in $(./scripts/deployment/fleet.sh list 2>/dev/null | grep -v "Available" || echo "cortex"); do
    echo "🔍 Checking $host..."
    just check "$host" || true
  done

# ====== SECRETS MANAGEMENT ======

# Edit secrets
edit-secrets:
  sops ../nixos-secrets/secrets.yaml

# Rekey all secrets (after adding new host/user keys)
rekey:
  #!/usr/bin/env bash
  cd ../nixos-secrets
  for file in *.yaml; do
    echo "🔑 Rekeying $file..."
    sops updatekeys -y "$file"
  done
  echo "✅ All secrets rekeyed"

# ====== DEVELOPMENT ENVIRONMENT ======

# Start development environment in any directory
dev *ARGS:
  #!/usr/bin/env bash
  # Get target directory (default to current directory)
  TARGET_DIR="${1:-$(pwd)}"
  
  # Always run from nixos config directory for proper nix environment
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  CONFIG_DIR="$HOME/.config/nixos"
  
  # If we're not already in the nixos config directory, we need to find it
  if [[ ! -f "$CONFIG_DIR/justfile" ]]; then
    echo "❌ Could not find nixos config directory"
    exit 1
  fi
  
  echo "🚀 Starting dev environment..."
  exec "$CONFIG_DIR/scripts/development/dev-shell.sh" "$TARGET_DIR"

# ====== UTILITIES ======

# Check flake (validate all configs)
check-all:
  nix flake check --show-trace

# Format all Nix files
fmt:
  nix fmt

# Git status with context
status:
  @git status
  @echo ""
  @echo "📦 Current Generation:"
  @readlink /run/current-system | grep -oP 'system-\K[0-9]+' || echo "N/A"
  @echo ""
  @echo "📦 Flake Inputs:"
  @nix flake metadata | grep -A 10 "Inputs:" || true

# Show disk usage
disk:
  @df -h / /home | grep -v tmpfs

# Show recent builds
generations:
  @sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -10

# Clean old generations (keep last 30 days)
clean:
  @echo "🧹 Cleaning old generations..."
  sudo nix-collect-garbage --delete-older-than 30d
  @echo "🔄 Updating bootloader..."
  sudo nixos-rebuild boot --flake .#$(hostname)
  @echo "✅ Cleanup complete"

# Deep clean (keeps only current generation - use with caution!)
clean-aggressive:
  @echo "⚠️  This will delete ALL old generations!"
  @read -p "Are you sure? (y/N) " -n 1 -r
  @echo
  @if [[ $REPLY =~ ^[Yy]$ ]]; then \
    sudo nix-collect-garbage -d; \
    sudo nixos-rebuild boot --flake .#$(hostname); \
    echo "✅ Aggressive cleanup complete"; \
  else \
    echo "❌ Cancelled"; \
  fi

# Show what changed between current and previous generation
diff-generations:
  #!/usr/bin/env bash
  CURRENT=$(readlink /run/current-system)
  PREVIOUS=$(ls -d /nix/var/nix/profiles/system-*-link | sort -V | tail -2 | head -1)
  echo "📦 Comparing:"
  echo "  Previous: $PREVIOUS"
  echo "  Current:  $CURRENT"
  echo ""
  nix store diff-closures "$PREVIOUS" "$CURRENT"

# ====== HELP & INFO ======

# Show detailed help for common tasks
help:
  @echo "🚀 NixOS Fleet Management - Common Tasks"
  @echo ""
  @echo "📍 Quick Start:"
  @echo "  just rebuild           - Rebuild current host"
  @echo "  just deploy cortex     - Deploy to Cortex with safety checks"
  @echo "  just check cortex      - Pre-flight checks only"
  @echo "  just ssh cortex        - SSH into Cortex"
  @echo ""
  @echo "🔨 Building:"
  @echo "  just build <host>      - Build config locally (test)"
  @echo "  just rebuild           - Rebuild current system"
  @echo "  just rebuild-trace <h> - Debug build issues"
  @echo ""
  @echo "🚀 Deploying:"
  @echo "  just deploy <host>     - Deploy with auto IP/user"
  @echo "  just deploy-manual <host> <ip> <user> - Override IP/user"
  @echo "  just rollback <host>   - Rollback to previous gen"
  @echo ""
  @echo "🔍 Fleet:"
  @echo "  just fleet-list        - List all systems"
  @echo "  just fleet-check       - Check all systems"
  @echo "  just fleet-deploy <h>  - Deploy to multiple"
  @echo ""
  @echo "🔧 Maintenance:"
  @echo "  just update            - Update all inputs"
  @echo "  just clean             - Clean old generations"
  @echo "  just generations       - Show recent builds"
  @echo ""
  @echo "📝 Run 'just' to see all commands"

# Show system information

