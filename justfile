# justfile - Task automation for NixOS config
# Run `just` to see all commands

# Default: show available commands
default:
  @just --list

# ====== PRE/POST HOOKS (EmergentMind Pattern) ======

# Run BEFORE every rebuild/deploy - syncs secrets automatically
rebuild-pre: update-secrets
  @git add --intent-to-add .

# Run AFTER rebuild - validate sops is working
rebuild-post:
  @echo "✅ Rebuild complete"
  @systemctl --user is-active sops-nix.service > /dev/null && echo "✅ sops-nix active" || echo "⚠️  sops-nix check manually"

# Sync secrets from separate repo (HYBRID APPROACH)
update-secrets:
  @echo "🔄 Syncing secrets..."
  @(cd ../nixos-secrets && git pull) || true
  @nix flake update nixos-secrets --timeout 5
  @echo "✅ Secrets synced"

# ====== LOCAL OPERATIONS ======

# Rebuild Orion (laptop) with pre/post hooks
rebuild-orion: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#orion switch

# Rebuild Cortex (AI rig) - if running locally on Cortex
rebuild-cortex: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#cortex switch

# Rebuild with trace for debugging
rebuild-trace HOST: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#{{HOST}} --show-trace switch

# ====== UPDATE COMMANDS ======

# Update all flake inputs
update:
  nix flake update

# Update specific input
update-input INPUT:
  nix flake update {{INPUT}}

# Update + rebuild Orion
update-orion: update
  just rebuild-orion

# Update + deploy to Cortex
update-cortex: update rebuild-pre
  just deploy-cortex

# ====== REMOTE OPERATIONS ======

# Deploy to Cortex (with safety checks + secrets sync)
deploy-cortex: rebuild-pre
  ./scripts/safe-deploy.sh cortex cortex.home jarvis

# Pre-flight checks only (no deploy)
check-cortex:
  ./scripts/pre-flight.sh cortex cortex.home jarvis

# Validate Cortex (post-deploy check)
validate-cortex:
  ./scripts/validate.sh cortex cortex.home jarvis

# SSH into Cortex
ssh-cortex:
  ssh jarvis@cortex.home

# Sync configs to remote host (without building)
sync-cortex:
  rsync -av --exclude='.git' --exclude='result' --exclude='*.md' \
    . jarvis@cortex.home:~/.config/nixos

# ====== SECRETS MANAGEMENT ======

# Edit secrets
edit-secrets:
  sops ../nixos-secrets/secrets.yaml

# Rekey all secrets (after adding new host/user keys)
rekey:
  cd ../nixos-secrets && \
  for file in $(ls *.yaml); do sops updatekeys -y $$file; done

# ====== FLEET MANAGEMENT ======

# Fleet status (your custom script)
fleet-status:
  ./scripts/fleet.sh status

# Fleet deploy (when you have multiple systems)
fleet-deploy HOSTS:
  ./scripts/fleet.sh deploy {{HOSTS}}

# ====== UTILITIES ======

# Check flake (validate all configs)
check:
  nix flake check --show-trace

# Format all Nix files
fmt:
  nix fmt

# Git status with context
status:
  @git status
  @echo ""
  @echo "📦 Current Generation:"
  @readlink /run/current-system | grep -oP 'system-\K[0-9]+'
  @echo ""
  @echo "📦 Flake Inputs:"
  @nix flake metadata | grep -A 10 "Inputs:"

# Show disk usage
disk:
  @df -h / /home | grep -v tmpfs

# Show recent builds
generations:
  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -10

# Clean old generations (keep last 5)
clean:
  sudo nix-collect-garbage --delete-older-than 30d
  sudo nixos-rebuild boot --flake .#$(hostname)
