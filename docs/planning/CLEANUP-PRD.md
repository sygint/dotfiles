# PRD: Repository Cleanup and Consolidation

**Status:** Draft  
**Created:** January 22, 2026  
**Priority:** High  
**Estimated Effort:** 8-16 hours over 1-2 weeks

---

## Executive Summary

This repository has accumulated **organizational debt** that needs addressing:
- Duplicate configuration files with conflicting data
- Security vulnerabilities (hardcoded password)
- 1.4GB of committed VM images
- Scattered documentation (39+ files)
- Root-level clutter (40+ files)
- Orphaned and unused modules

While the core architecture (dendritic pattern, feature modules) is excellent, these issues create maintenance burden and deployment risks.

---

## Goals

### Primary Goals
1. **Eliminate duplicate sources of truth** - Single network config, single doc location
2. **Fix security vulnerabilities** - Remove hardcoded passwords
3. **Reduce repository bloat** - Remove 1.4GB of VM images and temp files
4. **Improve discoverability** - Consolidate documentation, clean up root directory
5. **Standardize patterns** - Consistent configuration across all systems

### Non-Goals
- Not changing the dendritic pattern or feature module architecture (working well)
- Not removing functionality (only cleanup and consolidation)
- Not changing deployment methods (deploy-rs stays)
- Not migrating to different tools (staying with current stack)

---

## Problem Analysis

### Critical Issues (Must Fix)

#### 1. Duplicate Network Configuration Files ⚠️ CRITICAL

**Problem:**
Two network config files with **conflicting IP addresses**:

```
fleet-config.nix:
  cortex.ip = "192.168.1.10"
  orion.ip = "192.168.1.30"
  nexus.ip = "192.168.1.22"

network-config.nix:
  cortex.ip = "192.168.1.7"    # ❌ CONFLICT
  orion.ip = "192.168.1.100"   # ❌ CONFLICT
  (nexus missing entirely)
```

**Current Usage:**
- Orion: Uses `fleet-config.nix` ✅
- Nexus: Uses `fleet-config.nix` ✅
- Cortex: Uses `network-config.nix` ❌ WRONG FILE
- Axon: Doesn't use either ❌ HARDCODED

**Impact:**
- Cortex may connect to wrong IP
- Deployment scripts may target wrong host
- Network scripts use inconsistent addresses

**Root Cause:**
- `network-config.nix` created first
- `fleet-config.nix` added later with more features
- Migration incomplete
- Cortex never updated to new file

---

#### 2. Hardcoded Password ⚠️ SECURITY

**File:** `systems/cortex/variables.nix:23`

```nix
user = {
  username = "syg";
  syncPassword = "syncmybattleship";  # ❌ SECURITY ISSUE
};
```

**Problem:**
- Password committed to git (visible in history)
- Not encrypted with sops-nix
- Public repository = exposed credentials

**Impact:**
- If used for actual authentication, this is a security breach
- Appears to be for Syncthing sync (moderate risk)
- Bad security practice regardless

---

#### 3. Large Binary Files Committed ⚠️ CRITICAL

**Files:**
- `orion.qcow2` - 688MB
- `nexus.qcow2` - 751MB
- Total: **1.4GB**

**Problem:**
- Already in `.gitignore` but still in git history
- Bloats repository size
- Slows down clones
- No reason to version VM disk images

**Impact:**
- Slow `git clone` for new users
- Wastes GitHub storage
- Unnecessary bandwidth usage

---

#### 4. Duplicate Documentation (8+ copies) ⚠️ HIGH

**Security Docs (8 copies!):**
```
Root level:
  docs/SECURITY.md
  docs/SECURITY-ROADMAP.md
  docs/SECURITY-SCANNING.md
  docs/CORTEX-SECURITY.md

Subdirectory:
  docs/security/SECURITY.md (duplicate)
  docs/security/SECURITY-ROADMAP.md (duplicate)
  docs/security/SECURITY-SCANNING.md (duplicate)
  docs/security/CORTEX-SECURITY.md (duplicate)
```

**TODO Docs (3 copies):**
```
  docs/TODO-CHECKLIST.md
  docs/planning/TODO-CHECKLIST.md
  docs/planning/TODO-HTTPS-MIGRATION.md
```

**Impact:**
- Confusion about which file is canonical
- Updates to one don't propagate to others
- Outdated information likely present

---

### High Priority Issues

#### 5. Root-Level Clutter

**Files that don't belong in root:**

| File | Size | Issue | Action |
|------|------|-------|--------|
| `sqlite3` | 0 bytes | Empty file | DELETE |
| `build.log` | 2.1KB | Build artifact | DELETE |
| `nohup.out` | 392 bytes | Process output | DELETE |
| `test-focalboard-home.nix` | 123 bytes | Test file | Move to `tests/` |
| `flake.nix.bak` | 9KB | Backup file | DELETE |
| `claude-god-mode.txt` | 54KB | AI prompt | Move to `prompts/` |
| `notes.txt` | 206 bytes | Notes | Consolidate with `config/notes.txt` |
| `monitors.json` | 141 bytes | Orion-specific | Move to `systems/orion/` |

**Total clutter:** 10 files that should be elsewhere or deleted

---

#### 6. Backup Files in Repository

**Files:**
- `flake.nix.bak` (root)
- `systems/nexus/default.nix.bak`

**Problem:** Using manual backups instead of git history

---

#### 7. Hardcoded Values Scattered

**IP Addresses Hardcoded:**
```nix
# systems/orion/default.nix:68
networking.extraHosts = ''
  192.168.1.7 cortex.home cortex  # Should use fleet-config
'';

# systems/nexus/default.nix:multiple
device = "192.168.1.136:/volume1/Media/Movies";  # NAS IP
ignoreIP = [ "192.168.1.0/24" ];

# systems/axon/default.nix:59
networking.extraHosts = ''
  192.168.1.7 cortex.home cortex
'';
```

**Timezone Hardcoded:**
```nix
# systems/axon/default.nix:22
time.timeZone = "America/Los_Angeles";  # Should use fleet-config
```

**State Version Duplicated (8 times):**
Every system file declares:
```nix
system.stateVersion = "24.11";
```

---

#### 8. Orphaned Modules

**Modules that appear unused:**

1. **`modules/system/kanboard.nix`** (132 lines)
   - No references in any system config
   - Cortex-specific service but not enabled
   - May be legacy from previous setup

2. **`modules/system/system/secrets-password-sync.nix`** (72 lines)
   - Defined but never enabled in any system
   - No `modules.system.secrets-password-sync.enable` found

3. **`modules/system/locale.nix`** (18 lines)
   - Not explicitly imported
   - May be auto-imported via import-tree
   - Unclear if actually used

---

#### 9. Empty Directories

**Directories with no content:**
- `PRDs/` - Completely empty
- `prompts/` - Completely empty
- `tools/` - Completely empty

**Impact:** Clutters repository structure, unclear purpose

---

#### 10. Triple Kanboard API Implementation

**Files:**
- `scripts/kanboard/kanboard-api.sh` (Bash)
- `scripts/kanboard/kanboard-api.mjs` (Node.js)
- `scripts/kanboard/kanboard-api.ts` (Deno/TypeScript)

**Problem:** Three implementations of the same API client

**Decision needed:** Which one is actually used?

---

### Medium Priority Issues

#### 11. Configuration Duplication

**Boot Loader Config:**
Every system except Orion duplicates:
```nix
boot = {
  loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };
};
```
This is **already in** `modules/system/base/default.nix`

**Nix Settings Duplication:**
```nix
# modules/system/base/default.nix - Global
nix.settings = {
  experimental-features = [ "nix-command" "flakes" ];
  trusted-users = [ "root" "@wheel" ];
  max-jobs = 4;
};

# Multiple systems re-declare parts of this
```

---

#### 12. Confusing Module Organization

**Directory structure:**
```
modules/system/
├── ai-services/        # Subdirectory
├── base/              # Subdirectory
├── kanboard.nix       # Standalone
├── locale.nix         # Standalone
└── system/            # ❌ "system" inside "system"
    └── secrets-password-sync.nix
```

**Problem:** `modules/system/system/` is confusingly named

---

#### 13. Commented Dead Code

**High comment counts indicate dead code:**
- `orion/default.nix`: 68 comment lines
- `nexus/default.nix`: 71 comment lines
- `cortex/default.nix`: 71 comment lines
- `axon/default.nix`: 75 comment lines

**Examples of dead code to remove:**
```nix
# xserver.enable = true;  # Commented out
# programs.mtr.enable = true;  # Example cruft
# services.home-assistant = { ... };  # Entire disabled service
# chromium  # Alternative browser (disabled for VM testing)
```

---

#### 14. Script Path Hardcoding

**Many scripts reference:**
```bash
/home/syg/.config/nixos
```

**Problem:** Breaks for other users or when repo is cloned elsewhere

**Better approach:** Use `$FLAKE_DIR` or detect dynamically

---

#### 15. Notes File Duplication

**Two notes files:**
- `/notes.txt` (8 lines) - Basic nix commands
- `/config/notes.txt` (43 lines) - Detailed with TODO items

**Content overlap:** Both contain similar flake commands

---

### Low Priority Issues

#### 16-20. Additional Issues

See detailed analysis document for:
- Missing READMEs in some directories
- Inconsistent module abstraction levels
- Monitor setup complexity
- Script organization improvements
- Documentation consolidation opportunities

---

## Solution Design

### Phase 1: Critical Security & Correctness (Week 1)

**Goal:** Fix security issues and eliminate conflicting configuration

**Tasks:**

1. **Consolidate Network Configuration**
   - Audit current usage of both files
   - Determine correct IPs (likely fleet-config is newer)
   - Add missing hosts (nexus, axon) to fleet-config
   - Update Cortex to use fleet-config
   - Update Axon to use fleet-config
   - Delete network-config.nix
   - Test all systems can resolve hostnames

2. **Fix Password Security**
   - Remove hardcoded password from cortex/variables.nix
   - Document if password is actually used anywhere
   - If needed, migrate to sops-nix encrypted secret
   - Rotate password if it was in use

3. **Remove Large Binary Files**
   - Delete from working directory
   - Remove from git history using `git filter-repo`
   - Update .gitignore to ensure they stay ignored
   - Document VM setup separately (not in git)

4. **Verify All Changes**
   - Test Orion builds
   - Test Cortex deploys
   - Test Nexus deploys
   - Test Axon builds

**Deliverables:**
- Single source of truth for network config
- No hardcoded passwords
- Repository size reduced by ~1.4GB
- All systems tested and working

**Risk Level:** Medium (deployment changes)

---

### Phase 2: Documentation Consolidation (Week 1-2)

**Goal:** Single location for each document, clear organization

**Tasks:**

1. **Consolidate Security Documentation**
   - Keep `docs/security/` as canonical location
   - Delete root-level duplicates:
     - `docs/SECURITY.md`
     - `docs/SECURITY-ROADMAP.md`
     - `docs/SECURITY-SCANNING.md`
     - `docs/CORTEX-SECURITY.md`
   - Update all references to point to `docs/security/`

2. **Consolidate TODO Documentation**
   - Merge into single `docs/planning/TODO.md`
   - Archive or delete duplicates
   - Consider using GitHub Issues instead

3. **Update Documentation Index**
   - Update `DOCS.md` with new paths
   - Update `README.md` with new structure
   - Add README to empty directories explaining purpose

**Deliverables:**
- All security docs in `docs/security/` only
- Single TODO document or GitHub Issues
- Updated index files
- 8-10 fewer doc files

**Risk Level:** Low (documentation only)

---

### Phase 3: Root Directory Cleanup (Week 2)

**Goal:** Clean, organized root with only essential files

**Tasks:**

1. **Delete Temporary/Generated Files**
   - `sqlite3` (empty file)
   - `build.log` (build artifact)
   - `nohup.out` (process output)
   - `flake.nix.bak` (backup file)
   - `systems/nexus/default.nix.bak`

2. **Move Files to Appropriate Locations**
   - `test-focalboard-home.nix` → `tests/test-focalboard-home.nix`
   - `claude-god-mode.txt` → `prompts/claude-god-mode.txt`
   - `monitors.json` → `systems/orion/monitors.json`
   - Merge `/notes.txt` into `/config/notes.txt`, delete `/notes.txt`

3. **Handle Empty Directories**
   - `PRDs/` - Add README or delete
   - `prompts/` - Move claude-god-mode.txt here, add README
   - `tools/` - Add README explaining future use or delete

4. **Update .gitignore**
   - Ensure patterns catch all temp files
   - Add common patterns for VM images, logs, etc.

**Deliverables:**
- Root directory with ~15-20 files (down from 40+)
- All files in logical locations
- Clear purpose for every directory

**Risk Level:** Low (no functional changes)

---

### Phase 4: Configuration Standardization (Week 2-3)

**Goal:** DRY principle applied, consistent patterns

**Tasks:**

1. **Centralize Global Settings**
   - Add to fleet-config.nix:
     ```nix
     global = {
       stateVersion = "24.11";
       timeZone = "America/Los_Angeles";
       locale = "en_US.UTF-8";
       nas = {
         ip = "192.168.1.136";
         hostname = "synology";
         domain = "synology.home";
       };
     };
     ```

2. **Remove Hardcoded Values**
   - Update Orion: Use `fleetConfig.hosts.cortex.ip` for extraHosts
   - Update Nexus: Use `fleetConfig.global.nas.ip` for NFS mounts
   - Update Axon: Use `fleetConfig.global.timeZone` instead of hardcoded
   - Remove all `system.stateVersion` declarations (use fleet default)

3. **Remove Boot Config Duplication**
   - Verify base module has boot config
   - Remove from system configs (trust base module)
   - Only override when system needs different config

4. **Standardize Nix Settings**
   - Keep in base module only
   - Systems only override if needed
   - Document override pattern

**Deliverables:**
- Fleet-config is single source of truth for all shared config
- No duplicate boot/nix settings
- All IPs/hostnames come from fleet-config

**Risk Level:** Medium (configuration changes)

---

### Phase 5: Module Organization (Week 3)

**Goal:** Clear module structure, remove unused modules

**Tasks:**

1. **Audit Unused Modules**
   - `modules/system/kanboard.nix` - Delete or enable for Cortex
   - `modules/system/system/secrets-password-sync.nix` - Delete or document usage
   - `modules/system/locale.nix` - Verify import-tree picks it up or delete

2. **Reorganize System Modules**
   ```
   modules/system/
   ├── ai-services/
   ├── base/
   ├── services/
   │   ├── kanboard.nix (if keeping)
   │   └── locale.nix
   └── utilities/
       └── secrets-password-sync.nix (if keeping)
   ```
   Eliminate `modules/system/system/` confusion

3. **Clean Up Commented Code**
   - Remove disabled services from system configs
   - Keep only explanatory comments
   - Use git for history, not comments

**Deliverables:**
- Clear module organization
- No orphaned modules
- Minimal commented dead code

**Risk Level:** Low to Medium

---

### Phase 6: Script and Tooling Cleanup (Week 3-4)

**Goal:** Organized, maintainable scripts

**Tasks:**

1. **Consolidate Kanboard API**
   - Determine which implementation is used (bash/node/deno)
   - Delete unused implementations
   - Document the choice

2. **Fix Script Paths**
   - Replace `/home/syg/.config/nixos` with:
     ```bash
     FLAKE_DIR="${FLAKE_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
     ```
   - Test scripts work from different locations

3. **Move Misplaced Scripts**
   - `diagnose-hyprland.sh` → `scripts/desktop/`

4. **Archive Cleanup**
   - Review scripts in `archive/`
   - Delete if truly obsolete
   - Document if keeping for reference

**Deliverables:**
- One Kanboard API implementation
- Location-independent scripts
- Clean archive

**Risk Level:** Low

---

## Rollout Plan

### Week 1: Critical Fixes
- **Day 1-2:** Phase 1 (Network config, security)
- **Day 3-4:** Testing and verification
- **Day 5:** Phase 2 (Documentation consolidation)

### Week 2: Organization
- **Day 1-2:** Phase 3 (Root cleanup)
- **Day 3-5:** Phase 4 (Configuration standardization)

### Week 3-4: Polish
- **Week 3:** Phase 5 (Module organization)
- **Week 4:** Phase 6 (Scripts cleanup)

**Total estimated time:** 8-16 hours over 3-4 weeks

---

## Testing Strategy

### Pre-Cleanup
1. **Baseline:** Verify all systems build successfully
2. **Document:** Current IPs, hostnames, deployment status
3. **Backup:** Create git tag `pre-cleanup-2026-01-22`

### During Cleanup (Each Phase)
1. **Build Test:** `nix flake check --no-build`
2. **Eval Test:** `nixos-rebuild build --flake .#<system>`
3. **Deploy Test:** Test deploy to at least one system
4. **Smoke Test:** Verify critical services still work

### Post-Cleanup
1. **Full Fleet Build:** Build all 4 systems
2. **Deploy Test:** Deploy to all remote systems
3. **Documentation Review:** Verify all docs point to correct locations
4. **Size Verification:** Confirm repository size reduction

---

## Success Criteria

### Quantitative
- [ ] Repository size reduced by ~1.4GB (VM images removed)
- [ ] Root directory files reduced from 40+ to 15-20
- [ ] Documentation files reduced by 8-10 (consolidation)
- [ ] No duplicate configuration files
- [ ] No hardcoded passwords
- [ ] No `.bak` backup files

### Qualitative
- [ ] All 4 systems build successfully
- [ ] All deployments work correctly
- [ ] Documentation is organized and discoverable
- [ ] New contributors can understand structure quickly
- [ ] No confusion about which config file to use
- [ ] Scripts work from any location

### Verification
- [ ] `nix flake check` passes
- [ ] `nixos-rebuild build --flake .#orion` succeeds
- [ ] `nixos-rebuild build --flake .#cortex` succeeds
- [ ] `nixos-rebuild build --flake .#nexus` succeeds
- [ ] `nixos-rebuild build --flake .#axon` succeeds
- [ ] Grep shows no references to `network-config.nix`
- [ ] Grep shows no hardcoded passwords
- [ ] `du -sh .git` shows size reduction

---

## Risks and Mitigations

### Risk 1: Breaking System Deployments
**Probability:** Medium  
**Impact:** High  
**Mitigation:**
- Test each change incrementally
- Use git branches for each phase
- Keep rollback plan ready
- Test on non-critical system first (Axon)

### Risk 2: Losing Configuration History
**Probability:** Low  
**Impact:** Medium  
**Mitigation:**
- Create git tag before major changes
- Document removed files in commit messages
- Don't delete until sure it's unused

### Risk 3: Network Config Migration Issues
**Probability:** Medium  
**Impact:** High  
**Mitigation:**
- Audit all usage before deletion
- Search entire codebase for references
- Test connectivity after migration
- Keep network-config.nix until confirmed working

### Risk 4: Git History Rewrite Issues
**Probability:** Low  
**Impact:** High  
**Mitigation:**
- Use `git filter-repo` (safer than filter-branch)
- Backup repository before rewrite
- Only remove VM images, not code
- Communicate to any collaborators

---

## Dependencies

### Tools Required
- `git filter-repo` - For removing large files from history
- `ripgrep` / `rg` - For searching codebase
- `nix` - For testing builds

### Knowledge Required
- Understanding of fleet-config structure
- NixOS module system
- Git history rewriting
- Network configuration patterns

### Systems Access
- Ability to test deploy to all 4 systems
- SSH access to remote systems
- Ability to rollback if issues occur

---

## Deliverables

### Code
- [ ] Single network configuration file (fleet-config.nix)
- [ ] All systems using fleet-config
- [ ] No hardcoded passwords
- [ ] Organized root directory
- [ ] Consolidated documentation
- [ ] Clean module structure
- [ ] Standardized scripts

### Documentation
- [ ] Migration guide for network config changes
- [ ] Updated DOCS.md with new structure
- [ ] Updated README.md
- [ ] Cleanup summary document

### Testing
- [ ] All systems build successfully
- [ ] All deployments work
- [ ] Smoke tests pass

---

## Open Questions

1. **Kanboard module:** Is this actively used? Enable for Cortex or delete?
2. **secrets-password-sync:** Is this service actually needed? Enable or delete?
3. **locale.nix:** Is import-tree picking this up? Verify or delete?
4. **Kanboard API:** Which implementation (bash/node/deno) is actually used?
5. **VM images:** Where should VM testing instructions live?
6. **Password rotation:** Is the exposed Syncthing password in active use?

---

## Approvals

**Author:** OpenCode Agent  
**Reviewer:** TBD  
**Approver:** @sygint

---

## References

- [Critical Analysis Document](../analysis/critical-analysis.md)
- [Dendritic Migration Guide](../DENDRITIC-MIGRATION.md)
- [Fleet Configuration Documentation](../../FLEET-MANAGEMENT.md)
- [Git Filter Repo Docs](https://github.com/newren/git-filter-repo)

---

**Last Updated:** January 22, 2026  
**Status:** Draft - Awaiting Review
