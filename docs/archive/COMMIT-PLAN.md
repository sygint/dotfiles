# Commit Plan: November 2025 Dotfiles Changes

This document tracks the recommended commit breakdown for the current set of uncommitted changes in the dotfiles repo.

---

## 1. New Documentation
- `docs/GLOBAL-SETTINGS.md`
- `docs/HTPC-SETUP.md`
- `docs/KIOSK-MODE.md`
- `docs/VM-TESTING.md`
- `docs/VPRO-AMT-SETUP.md`
- `docs/planning/homelab-strategy.md`
- **Commit:**
  - `docs: add architecture and setup docs (GLOBAL-SETTINGS, HTPC-SETUP, KIOSK-MODE, VM-TESTING, VPRO-AMT-SETUP, homelab strategy)`

## 2. Flatpak Service Module
- `modules/system/services/flatpak.nix`
- **Commit:**
  - `feat(modules): add Flatpak service module`

## 3. Nexus Host Additions
- `systems/nexus/DEPLOYMENT.md`
- `systems/nexus/README.md`
- `systems/nexus/disk-config.nix`
- `systems/nexus/hardware.nix`
- `systems/nexus/variables.nix`
- `systems/nexus/default.nix`
- **Commit:**
  - `feat(nexus): add host configuration and docs`

## 4. Axon Host
- `systems/axon/README.md`
- `systems/axon/default.nix`
- **Commit:**
  - `docs(axon): add host README and update config`

## 5. Orion Display/Monitor Updates
- `systems/orion/monitors.json`
- `systems/orion/default.nix`
- `systems/orion/homes/syg.nix`
- `systems/orion/variables.nix`
- **Commit:**
  - `feat(orion): configure monitors and host settings`

## 6. Cortex Host
- `systems/cortex/default.nix`
- `systems/cortex/variables.nix`
- **Commit:**
  - `chore(cortex): update host config and variables`

## 7. Module and Lib Updates
- `lib/network.nix`
- `modules/system/base/default.nix`
- `modules/system/system/security.nix`
- **Commit:**
  - `chore(modules): update base and security modules`
  
  - NOTE: `lib/network.nix` has been removed from the active tree and its functionality migrated to the standalone `nixos-fleet` flake. Update any remaining docs or scripts to reference `nixos-fleet`.

## 8. Flake Updates
- `flake.nix`
- `flake.lock`
- **Commit:**
  - `chore(flake): update flake and lockfile`

## 9. Repo Docs and Scripts
- `.gitignore`
- `README.md`
- `ISSUES.md`
- `docs/BOOTSTRAP.md`
- `scripts/README.md`
- **Commit:**
  - `docs: update bootstrap, project, and scripts docs`
  
  - NOTE: Fleet helper scripts were migrated to `nixos-fleet` — replace references to `./scripts/deployment/fleet.sh` and similar with `nix run github:sygint/nixos-fleet#fleet -- <command>` or update `flake.nix` inputs.

## 10. Legacy/Deleted Files
- `network-config.nix` (deleted)
- **Commit:**
  - `chore(network): remove legacy network-config.nix`

## 11. VS Code User Settings
- `dotfiles/.config/Code/User/keybindings.json`
- `dotfiles/.config/Code/User/settings.json`
- **Commit:**
  - `chore(vscode): update user settings and keybindings`

## 12. Other Artifacts
- `orion.qcow2` (ignored, no commit needed)

---

**Instructions:**
- Work through each group, staging and committing as described.
- Adjust groupings if new changes are made before committing.
- Use this file as a checklist and update as you go.
