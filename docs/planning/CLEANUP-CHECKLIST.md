# Repository Cleanup Checklist

Quick reference for the cleanup phases. See [CLEANUP-PRD.md](CLEANUP-PRD.md) for full details.

---

## 🔴 CRITICAL ISSUES (Fix First)

### Network Configuration
- [ ] Audit usage of `network-config.nix` vs `fleet-config.nix`
- [ ] Verify correct IPs (Cortex: 192.168.1.7 or .10?)
- [ ] Add missing hosts to fleet-config (nexus, axon)
- [ ] Update Cortex to use fleet-config
- [ ] Update Axon to use fleet-config
- [ ] Delete network-config.nix
- [ ] Test hostname resolution on all systems

### Security
- [ ] Remove hardcoded password from `systems/cortex/variables.nix:23`
- [ ] Check if password is in active use
- [ ] Migrate to sops-nix if needed
- [ ] Rotate password if exposed

### Binary Files
- [ ] Delete `orion.qcow2` (688MB)
- [ ] Delete `nexus.qcow2` (751MB)
- [ ] Remove from git history with `git filter-repo`
- [ ] Verify .gitignore prevents re-adding

---

## 🟡 HIGH PRIORITY

### Documentation Consolidation
- [ ] Delete `docs/SECURITY.md` (duplicate)
- [ ] Delete `docs/SECURITY-ROADMAP.md` (duplicate)
- [ ] Delete `docs/SECURITY-SCANNING.md` (duplicate)
- [ ] Delete `docs/CORTEX-SECURITY.md` (duplicate)
- [ ] Keep only `docs/security/*` versions
- [ ] Merge TODO docs into one location
- [ ] Update all references

### Root Directory Cleanup
- [ ] Delete `sqlite3` (empty file)
- [ ] Delete `build.log` (temp file)
- [ ] Delete `nohup.out` (temp file)
- [ ] Delete `flake.nix.bak` (backup)
- [ ] Delete `systems/nexus/default.nix.bak` (backup)
- [ ] Move `test-focalboard-home.nix` → `tests/`
- [ ] Move `claude-god-mode.txt` → `prompts/`
- [ ] Move `monitors.json` → `systems/orion/`
- [ ] Merge `/notes.txt` into `/config/notes.txt`

### Orphaned Modules
- [ ] Decide: Keep or delete `modules/system/kanboard.nix`?
- [ ] Decide: Keep or delete `modules/system/system/secrets-password-sync.nix`?
- [ ] Verify `modules/system/locale.nix` is imported
- [ ] Remove if unused

### Empty Directories
- [ ] `PRDs/` - Add README or delete
- [ ] `prompts/` - Add claude-god-mode.txt + README
- [ ] `tools/` - Add README or delete

---

## 🟢 MEDIUM PRIORITY

### Configuration Standardization
- [ ] Add global settings to fleet-config:
  - [ ] `stateVersion = "24.11"`
  - [ ] `timeZone = "America/Los_Angeles"`
  - [ ] NAS IP and hostname
- [ ] Remove hardcoded IPs from system configs
- [ ] Remove hardcoded timezone from Axon
- [ ] Remove duplicate boot loader config
- [ ] Remove duplicate nix settings

### Module Organization
- [ ] Rename `modules/system/system/` → `modules/system/utilities/`
- [ ] Or organize as `modules/system/services/`
- [ ] Clean up commented dead code in all system configs

### Scripts Cleanup
- [ ] Decide: Which Kanboard API? (bash/node/deno)
- [ ] Delete unused Kanboard implementations
- [ ] Fix hardcoded paths in scripts
- [ ] Move `diagnose-hyprland.sh` → `scripts/desktop/`

---

## 🔵 LOW PRIORITY

### Documentation
- [ ] Add READMEs to directories missing them
- [ ] Update DOCS.md with new structure
- [ ] Update README.md

### Code Quality
- [ ] Review module abstraction consistency
- [ ] Simplify monitor setup if possible
- [ ] Standardize script patterns

---

## Testing Checklist

### Before Starting
- [ ] Create git tag: `git tag pre-cleanup-2026-01-22`
- [ ] Document current state
- [ ] Verify all systems build

### After Each Phase
- [ ] `nix flake check --no-build`
- [ ] `nixos-rebuild build --flake .#orion`
- [ ] `nixos-rebuild build --flake .#cortex`
- [ ] `nixos-rebuild build --flake .#nexus`
- [ ] `nixos-rebuild build --flake .#axon`
- [ ] Deploy test to one system
- [ ] Commit changes

### After Completion
- [ ] All systems build successfully
- [ ] All deployments work
- [ ] Repository size reduced ~1.4GB
- [ ] Root directory has 15-20 files (down from 40+)
- [ ] No duplicate docs
- [ ] No hardcoded passwords
- [ ] No backup files

---

## Open Questions

Answer these before proceeding:

1. **Cortex IP:** Is it 192.168.1.7 or 192.168.1.10? Which is correct?
2. **Kanboard module:** Is this service actually used? Enable or delete?
3. **Syncthing password:** Is "syncmybattleship" in active use? Need to rotate?
4. **Kanboard API:** Which implementation is used - bash, node, or deno?
5. **locale.nix:** Is this module actually being imported and used?
6. **secrets-password-sync:** Is this service needed? What does it do?

---

## Phase Timeline

**Week 1: Critical Fixes**
- Days 1-2: Network config + security
- Days 3-4: Testing
- Day 5: Documentation consolidation

**Week 2: Organization**  
- Days 1-2: Root cleanup
- Days 3-5: Configuration standardization

**Week 3-4: Polish**
- Week 3: Module organization
- Week 4: Scripts cleanup

**Total effort:** 8-16 hours over 3-4 weeks

---

## Quick Commands

### Search for references
```bash
# Find all references to network-config.nix
rg "network-config\.nix"

# Find hardcoded IPs
rg "192\.168\.1\.\d+"

# Find hardcoded passwords
rg -i "password\s*=\s*\"[^\"]+\""

# Find backup files
find . -name "*.bak" ! -path "./.git/*"
```

### Remove large files from history
```bash
# Install git-filter-repo
nix-shell -p git-filter-repo

# Remove VM images
git filter-repo --path orion.qcow2 --path nexus.qcow2 --invert-paths

# Force push (careful!)
git push origin --force --all
```

### Test builds
```bash
# Quick check
nix flake check --no-build

# Full build test
nixos-rebuild build --flake .#orion
```

---

**Last Updated:** January 22, 2026  
**Status:** Ready to Execute
