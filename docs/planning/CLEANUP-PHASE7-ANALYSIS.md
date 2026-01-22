# NixOS Configuration Repository - Deep Cleanup Analysis

**Analysis Date:** January 22, 2026  
**Status:** Pending Implementation

---

## Executive Summary

After completing Phases 1-6 of the repository cleanup, a deep analysis revealed additional issues:

- **~1.4GB** in VM images that should be removed
- **Wrong IP address** in deploy.nix for Axon
- **Hardcoded values** in deploy.nix not using fleet-config.nix
- **Stale documentation** referencing old module paths
- **Empty directories** and backup files
- **Orphaned code** (unused lib/network.nix, archived scripts)

---

## 1. CRITICAL: Large Binary Files

### VM Images in Repository

| File | Size | Issue |
|------|------|-------|
| `orion.qcow2` | 688MB | VM image tracked in git |
| `nexus.qcow2` | 751MB | VM image tracked in git |

**Total: ~1.4GB**

**Priority:** HIGH  
**Recommended Action:**
1. Delete both files immediately
2. Verify `*.qcow2` is in `.gitignore`
3. Consider `git filter-repo` to purge from history if needed

---

## 2. CRITICAL: deploy.nix Issues

### Wrong IP Address
**File:** `flake-modules/deploy.nix`

| Line | Current Value | Correct Value | Issue |
|------|---------------|---------------|-------|
| 23 | `192.168.1.11` | `192.168.1.25` | **Wrong Axon IP** - would cause deployment failure |

### Hardcoded IPs (Should Use fleet-config)

| Line | Hardcoded Value | Should Use |
|------|-----------------|------------|
| 8 | `192.168.1.7` | `fleetConfig.hosts.cortex.ip` |
| 15 | `192.168.1.22` | `fleetConfig.hosts.nexus.ip` |
| 23 | `192.168.1.11` | `fleetConfig.hosts.axon.ip` |

**Priority:** HIGH  
**Recommended Action:** Refactor deploy.nix to import and use fleet-config.nix

---

## 3. Backup/Stale Files

| File | Issue | Action |
|------|-------|--------|
| `systems/nexus/default.nix.bak` | Backup file | Delete |
| `notes.txt` (root) | Stale notes | Delete |
| `config/notes.txt` | Stale TODOs (already done) | Delete |

**Priority:** MEDIUM

---

## 4. Empty Directories

| Directory | Contents | Action |
|-----------|----------|--------|
| `PRDs/` | Empty | Delete |
| `tools/` | Empty | Delete |

**Priority:** MEDIUM

---

## 5. Archived Scripts

### scripts/deployment/archive/

| File | Lines | Status |
|------|-------|--------|
| `fleet.sh.archived` | 500+ | Superseded by new fleet.sh |
| `check-system.sh.archived` | ~200 | Old utility |

**Priority:** MEDIUM  
**Action:** Delete entire archive directory

### archive/ (root)

| File | Description |
|------|-------------|
| `exec` | Old Colmena script |
| `generate-module-aggregator.sh` | Old utility |
| `leantime-cli.sh` | Old CLI (26KB) |
| `todo.sh` | Old CLI |
| `vikunja-cli.sh` | Old CLI |
| `devenv-bootstrap/` | Submodule - check if still used |

**Priority:** LOW  
**Action:** Review and delete unused scripts

---

## 6. Orphaned Code

### lib/network.nix (124 lines)

Contains helper functions but **not imported anywhere** in the codebase.

**Priority:** LOW  
**Action:** Either integrate into deploy.nix or delete

---

## 7. Stale Documentation

### Files with Old Module Path References

| File | Lines | Old Path Referenced |
|------|-------|---------------------|
| `README.md` | 189 | `modules/home/programs/librewolf.nix` |
| `ISSUES.md` | 17, 28, 37, 66, 189 | Various old paths |
| `docs/ARCHITECTURE.md` | Multiple | `modules/system/hardware/`, etc. |
| `docs/BOOTSTRAP.md` | Multiple | `network-config.nix` (deleted file) |
| `docs/troubleshooting/brave.md` | 102-103 | Old paths |

**Priority:** LOW-MEDIUM  
**Action:** Update to reference `modules/features/` structure

---

## 8. Other Hardcoded Values

### modules/features/security.nix

| Line | Value | Should Use |
|------|-------|------------|
| 65 | `"192.168.1.0/24"` | `fleetConfig.network.subnet` |

### systems/nexus/default.nix

| Line | Value | Should Use |
|------|-------|------------|
| 187 | `"192.168.1.0/24"` | `networkConfig.network.subnet` |

**Priority:** LOW

---

## 9. Axon Hardware Placeholders

### systems/axon/hardware.nix

| Lines | Issue |
|-------|-------|
| 19 | Placeholder UUID: `XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX` |
| 24 | Placeholder UUID: `XXXX-XXXX` |

**Priority:** MEDIUM (when deploying Axon)  
**Action:** Generate real hardware config on target machine

---

## Action Plan

### Phase 7A: Critical Fixes (Do First)

1. [ ] Delete VM images (`orion.qcow2`, `nexus.qcow2`)
2. [ ] Fix deploy.nix:
   - Import fleet-config.nix
   - Replace all hardcoded IPs
   - Fix wrong Axon IP (192.168.1.11 → 192.168.1.25)

### Phase 7B: Medium Priority Cleanup

3. [ ] Delete `systems/nexus/default.nix.bak`
4. [ ] Delete empty directories (`PRDs/`, `tools/`)
5. [ ] Delete stale notes files
6. [ ] Delete `scripts/deployment/archive/`

### Phase 7C: Low Priority Cleanup

7. [ ] Review/delete `lib/network.nix`
8. [ ] Clean up `archive/` scripts
9. [ ] Update stale documentation paths

---

## Estimated Impact

| Category | Before | After | Savings |
|----------|--------|-------|---------|
| Repository size | +1.4GB | -1.4GB | **1.4GB** |
| Stale files | 10+ | 0 | 10 files |
| Empty directories | 2 | 0 | 2 dirs |
| Hardcoded IPs | 5+ | 0 | Consistency |

---

## Verification Commands

After cleanup:

```bash
# Verify no VM images
ls -la *.qcow2

# Check builds
nix flake check --no-build

# Verify deploy.nix IPs match fleet-config
grep -n "192.168" flake-modules/deploy.nix

# Check for old path references
rg "modules/system/hardware/"
rg "modules/home/programs/"
rg "network-config.nix"
```
