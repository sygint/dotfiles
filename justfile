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
