# justfile - Task automation for NixOS config
# Run `just` to see all commands

# Default: show available commands
default:
  @just --list

# ====== PRE/POST HOOKS (EmergentMind Pattern) ======

# Run BEFORE every rebuild/deploy - syncs secrets automatically
rebuild-pre: update-secrets

# ====== FLEET MANAGEMENT ======

# Show fleet status (all hosts)
fleet-status:
  fleet status

# Deploy to a specific host
fleet-push HOST:
  fleet push {{HOST}}

# Deploy to all servers
fleet-push-servers:
  fleet push --tag server

# Deploy to all remote hosts
fleet-push-remote:
  fleet push --tag remote

# SSH into a host
fleet-ssh HOST:
  fleet ssh {{HOST}}

# Execute command on a host
fleet-exec HOST COMMAND:
  fleet exec {{HOST}} -- {{COMMAND}}

# Check health of a host
fleet-check HOST:
  fleet check {{HOST}}

# Update secrets from nixos-secrets repo
update-secrets:
  @echo "Syncing secrets from nixos-secrets repo..."
  @cd ~/.config/nixos-secrets && git pull --quiet
  @echo "✓ Secrets synced"

# Show system information
info:
