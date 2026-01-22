# Git History Analysis

Generated: 2026-01-22

## Executive Summary

This NixOS configuration repository spans **617 commits** over **14 months** (November 2024 - January 2026), evolving from a single-system setup to a **4-system fleet** with sophisticated infrastructure including flake-parts, deploy-rs, sops-nix secrets, and unified feature modules.

---

## Repository Timeline

| Date | Milestone |
|------|-----------|
| 2024-11-24 | Initial commit - basic NixOS configuration |
| 2025-08-31 | Renamed from "nixos" to **Orion** (primary workstation) |
| 2025-10-11 | Renamed "AIDA" to **Cortex** (AI/ML server) |
| 2025-11-09 | Renamed "HTPC" to **Axon** (home theater PC) |
| 2025-11-14 | Added **Nexus** (homelab server) |
| 2026-01-19 | Created `v1.0-pre-flake-parts` tag |
| 2026-01-20 | Migrated to **flake-parts** architecture |
| 2026-01-22 | Completed Phase 1-6 repository cleanup |

---

## Commit Statistics

### Total Commits: 617

### By Author
| Author | Commits | % |
|--------|---------|---|
| sygint | 379 | 61.4% |
| Sygint | 117 | 19.0% |
| syg | 107 | 17.3% |
| installer | 7 | 1.1% |
| Syg | 5 | 0.8% |
| copilot-swe-agent[bot] | 2 | 0.3% |

*Note: sygint/Sygint/syg/Syg are likely the same user with different git configs*

### By Month
| Month | Commits |
|-------|---------|
| Nov 2025 | 102 |
| Oct 2025 | 102 |
| Sep 2025 | 75 |
| Jan 2026 | 57 |
| Mar 2025 | 48 |
| Jun 2025 | 43 |
| Dec 2024 | 39 |
| Dec 2025 | 31 |
| Jan 2025 | 30 |
| Apr 2025 | 27 |
| May 2025 | 25 |
| Jul 2025 | 18 |
| Aug 2025 | 8 |
| Feb 2025 | 6 |
| Nov 2024 | 6 |

### Busiest Days
| Date | Commits | Notes |
|------|---------|-------|
| 2025-11-02 | 40 | Major refactoring day |
| 2025-10-10 | 28 | Cortex development |
| 2025-03-23 | 26 | - |
| 2026-01-22 | 25 | Repository cleanup |
| 2025-07-06 | 16 | - |

---

## System Evolution

### Orion (Primary Workstation)
- **Created**: 2025-08-31 (renamed from generic "nixos")
- **Purpose**: Main development workstation with Hyprland desktop
- **Key commit**: `e6ee5e4` - "Change hostname from nixos to orion"
- **Most changed file**: `systems/orion/default.nix` (66 changes)

### Cortex (AI/ML Server)
- **Created**: 2025-10-11 (renamed from "AIDA")
- **Purpose**: AI services, CUDA workloads
- **Key commit**: `3718de5` - "refactor: rename AIDA system to Cortex"
- **Changes**: 18 commits to `systems/cortex/default.nix`

### Axon (Home Theater PC)
- **Created**: 2025-11-09 (renamed from "HTPC")
- **Purpose**: Media center, Kodi, Jellyfin
- **Key commit**: `2bf5a32` - "Migrate HTPC to axon"
- **Recent**: ZSH migration completed 2026-01-22

### Nexus (Homelab Server)
- **Created**: 2025-11-14
- **Purpose**: Homelab services (Leantime, etc.)
- **Key commit**: `96b7ae8` - "feat(nexus): add complete homelab server"
- **Changes**: 14 commits to `systems/nexus/default.nix`

---

## Major Refactoring Events

### 1. Flake-Parts Migration (January 2026)
- **Tag**: `v1.0-pre-flake-parts`
- **Commits since migration**: 25
- **Key commits**:
  - `ed7b8df` - "refactor: migrate to flake-parts for modular flake composition (Phase 1)"
  - `f2fe9ba` - "feat: migrate to unified feature modules (Phase 2)"
  - `a73a823` - "refactor: migrate batch 2 modules to unified features - PHASE 2 COMPLETE"

### 2. Dendritic Module Architecture (January 2026)
- Converted modules to auto-import pattern
- Created unified feature modules in `modules/features/`
- **Key commits**:
  - `e00a0b5` - "feat(dendritic): add import-tree for automatic module imports"
  - `28247a2` - "feat(dendritic): convert system modules to auto-import"
  - `61ecb90` - "feat(dendritic): convert home modules to auto-import"

### 3. Security Infrastructure (Various)
- sops-nix secrets management
- git-secrets and TruffleHog integration
- fail2ban and auditd hardening
- **Key commits**:
  - `beef418` - "security: migrate Syncthing password to sops-nix secrets"
  - `db0b07c` - "feat(security): integrate git-secrets and TruffleHog"
  - `6dfe0c9` - "Add security hardening module with fail2ban and auditd"

### 4. Repository Cleanup (January 2026)
Phases 1-6 completed:
- `ad1123a` - Phase 1: Network config consolidation
- `d7e76fc` - Phase 2: Documentation cleanup
- `bd004d4` - Phase 3: Temp file cleanup
- `f1e70f3` - Phase 4: fleet-config centralization
- `a728034` - Phase 5: Unused module deletion
- `6d505c6` - Phase 6: Kanboard script removal

---

## Branch Analysis

### Active Branches
| Branch | Last Commit | Status |
|--------|-------------|--------|
| `main` | 2026-01-22 | Primary branch, 6 commits ahead of origin |
| `feature/axon-zsh-migration` | 2026-01-22 | Likely merged |
| `feature/unified-zsh-module` | 2026-01-22 | Likely merged |
| `feature/phase-1-flake-parts` | 2026-01-20 | Likely merged |

### Stale/Backup Branches
| Branch | Last Commit | Recommendation |
|--------|-------------|----------------|
| `backup/pre-flake-parts-migration` | 2026-01-19 | Keep as backup reference |
| `docs/flake-parts-dendritic-playbook` | 2026-01-19 | Can delete if merged |
| `origin/copilot/sub-pr-20` | 2026-01-22 | Review and delete |
| `origin/feature/add-gh-cli` | 2026-01-22 | Review and delete |

### Tags
| Tag | Description |
|-----|-------------|
| `v1.0-pre-flake-parts` | State before flake-parts migration |
| `pre-cleanup-2026-01-22` | State before Phase 1-6 cleanup |

---

## Most Changed Files

| File | Changes | Notes |
|------|---------|-------|
| `systems/orion/default.nix` | 66 | Main system config |
| `flake.nix` | 65 | Flake root |
| `systems/nixos/default.nix` | 63 | Legacy (renamed to orion) |
| `flake.lock` | 41 | Dependency updates |
| `modules/home/programs/hyprland.nix` | 40 | Desktop config |
| `systems/orion/homes/syg.nix` | 40 | User home config |
| `hosts/nixos/home.nix` | 40 | Legacy home config |
| `home/syg.nix` | 40 | Legacy structure |

---

## Large Files Issue

### Current State
Two VM disk images exist in the repository root:
- `nexus.qcow2` - 751 MB (added ~2025-11-22)
- `orion.qcow2` - 688 MB (added ~2025-12-27)

**Total**: 1.4 GB of binary data

### Impact
- These files are NOT tracked in git history (likely in `.gitignore`)
- They exist in the working directory only
- Should be stored externally (NAS, cloud storage)

### Recommendation
Delete from repository and document proper storage location.

---

## Commit Message Patterns

### Conventional Commits Adoption
The repository shows evolution toward conventional commits:

**Early style** (2024-2025):
- "Add new feature"
- "Fix bug"
- "Update config"

**Current style** (late 2025-2026):
- `feat:` - New features
- `fix:` - Bug fixes
- `refactor:` - Code restructuring
- `docs:` - Documentation
- `chore:` - Maintenance tasks
- `security:` - Security improvements

### Scoped Commits
System-specific scopes emerged:
- `feat(nexus):` - Nexus-specific changes
- `feat(orion):` - Orion-specific changes
- `fix(dev):` - Development environment fixes
- `feat(dendritic):` - Architecture changes

---

## Key Insights

### 1. Rapid Growth Period
October-November 2025 saw 204 commits (33% of total), indicating major feature development and the addition of Cortex, Axon, and Nexus systems.

### 2. Architecture Maturation
The migration to flake-parts and dendritic modules in January 2026 represents a significant maturation of the codebase, moving from ad-hoc configuration to a structured, maintainable architecture.

### 3. Security Focus
Multiple commits dedicated to security infrastructure (sops-nix, fail2ban, secret scanning) show a conscious effort to secure the fleet.

### 4. Cleanup Debt
The need for 6+ phases of cleanup in January 2026 indicates accumulated technical debt from rapid development. Future recommendation: regular maintenance sprints.

### 5. Naming Evolution
Systems went through naming iterations:
- nixos -> Orion
- AIDA -> Cortex
- HTPC -> Axon

This suggests the fleet naming convention ("constellation/neural network" theme) was established mid-project.

---

## Recommendations

### Immediate (Phase 7)
1. **Delete VM images** - Remove `*.qcow2` files (1.4 GB savings)
2. **Clean stale branches** - Merge or delete feature branches
3. **Fix deploy.nix** - Use fleet-config for all IPs

### Short-term
1. **Standardize git identity** - Consolidate author names
2. **Add branch protection** - Prevent direct pushes to main
3. **Automate cleanup** - Pre-commit hooks for file size limits

### Long-term
1. **Regular maintenance** - Monthly cleanup sprints
2. **Version tagging** - Tag stable states before major changes
3. **Documentation sync** - Keep docs updated with each major change
