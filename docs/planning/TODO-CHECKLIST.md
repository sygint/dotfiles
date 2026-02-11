# Implementation Checklist

**Start Date:** October 2025  
**Last Updated:** October 29, 2025  
**Current Status:** Week 1 ~60% Complete (4/7 days done)

Use this checklist to track your progress implementing improvements from the analysis.

---

## 📊 Quick Status Overview

**✅ Completed:** 
- Deployment Safety (Day 1-2) - Scripts created & tested
- Just Automation (Day 3) - 20+ commands with rebuild-pre hook
- Documentation (Day 4) - PROJECT-OVERVIEW, ARCHITECTURE, ROADMAP-VISUAL updated
- Week 2: Secrets management with automatic sync
- Week 3: Cortex provisioning (RTX 5090 + Ollama operational)

**❌ Not Started (Critical):** 
- Automated Backups (Day 6-7) - **P1 HIGHEST PRIORITY**
- Core/Optional Architecture (Day 4-5) - P2 (blocked by planning)

**🎯 Immediate Priorities:**

1. **P1 (CRITICAL): Automated Backups** - 2 hours estimated
   - Current: NO data protection for either system
   - Impact: Risk of configuration/data loss
   - Resources: Synology DS-920+ available but unused
   - See: IMPLEMENTATION-GUIDE.md Day 6-7 for implementation

2. **P2 (HIGH): Core/Optional Architecture** - 4 hours estimated
   - Current: Flat module structure (base/hardware/services/programs)
   - Impact: Scaling to 10+ systems, clearer organization
   - Blocker: Need to create MIGRATION-PLAN.md first
   - See: IMPLEMENTATION-GUIDE.md Day 3-5 for planning guide

3. **P3 (MEDIUM): Integrate Pre-flight Scripts** - 1 hour estimated
   - Current: Scripts exist but not default workflow
   - Impact: Make safe-deploy.sh the standard method
   - See: Update justfile and FLEET-MANAGEMENT.md

---

## ✅ Week 1: Critical Improvements (DO THESE FIRST)

### Day 1-2: Deployment Safety ✅ COMPLETED

- [x] Create `scripts/pre-flight.sh` (from IMPLEMENTATION-GUIDE.md)
- [x] Create `scripts/validate.sh` (from IMPLEMENTATION-GUIDE.md)
- [x] Create `scripts/safe-deploy.sh` (from IMPLEMENTATION-GUIDE.md)
- [x] Make scripts executable: `chmod +x scripts/*.sh`
- [x] Test pre-flight on Cortex: `./scripts/pre-flight.sh cortex 192.168.1.7 jarvis`
- [x] Test validation on Cortex: `./scripts/validate.sh cortex 192.168.1.7 jarvis`
- [x] Do one safe deploy: `./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis`
- [x] Update FLEET-MANAGEMENT.md with new workflow

**Success Metric:** ✅ Scripts created and tested successfully

**Status:** Scripts exist and work. Remaining: Integrate as default deployment method.

---

### Day 3: Just Automation ✅ COMPLETED

- [x] Add `just` to `environment.systemPackages`
- [x] Rebuild to install Just: `sudo nixos-rebuild switch --flake .#orion`
- [x] Create `justfile` in repo root (from IMPLEMENTATION-GUIDE.md)
- [x] Test: `just` (should show command list)
- [x] Test: `just rebuild-orion`
- [x] Test: `just check-cortex`
- [x] Test: `just deploy-cortex`
- [x] Update README.md with Just commands
- [x] Commit changes: `git add justfile && git commit -m "feat: add Just automation"`

**Success Metric:** ✅ justfile created with 20+ commands including rebuild-pre hook

**Status:** Fully operational. Added automatic secrets sync via rebuild-pre hook.

---

### Day 4: Documentation ✅ COMPLETED | Core/Optional Planning ❌ NOT STARTED

**Documentation (Day 4):**
- [x] Update PROJECT-OVERVIEW.md (October 29, 2025)
- [x] Create docs/ARCHITECTURE.md (500+ lines comprehensive guide)
- [x] Update QUICK-WINS.md with status tracking
- [x] Update ROADMAP-VISUAL.md with current progress
- [x] Consolidated secrets documentation into SECRETS.md

**Success Metric:** ✅ Documentation comprehensive and accurate

**Core/Optional Planning (Day 4 - alternative track):**
- [ ] Create `MIGRATION-PLAN.md` (from QUICK-WINS.md template)
- [ ] List all current system modules
- [ ] Mark each as [CORE] or [OPTIONAL]
- [ ] List all current home modules
- [ ] Mark each as [CORE] or [OPTIONAL]
- [ ] Review with fresh eyes - is this truly core?
- [ ] Schedule Day 5 for migration (2-3 hour block)

**Status:** Documentation completed instead. Core/Optional planning not started yet.

---

### Day 5: Core/Optional Migration ❌ NOT STARTED

- [ ] Create directories:
  ```bash
  mkdir -p modules/system/{core,optional,users}
  mkdir -p modules/home/{core,optional}
  ```
- [ ] Move system/base/* to system/core/
- [ ] Move everything else to system/optional/
- [ ] Create `modules/system/core/default.nix` with imports
- [ ] Move home/programs core files to home/core/
- [ ] Move everything else to home/optional/
- [ ] Update `systems/orion/default.nix` imports
- [ ] Update `systems/cortex/default.nix` imports
- [ ] Test rebuild Orion: `just rebuild-orion`
- [ ] Test deploy Cortex: `just deploy-cortex`
- [ ] Verify no regressions (check systemctl status)
- [ ] Commit: `git add -A && git commit -m "refactor: adopt core/optional architecture"`

**Success Metric:** ✅ Both systems rebuild successfully with new structure

**Status:** Blocked by Day 4 planning. Current structure is flat (base/hardware/services/programs).  
**Priority:** P2 (after backups). Estimated 4 hours (1hr audit + 3hrs migration).  
**Impact:** Enables scaling to 10+ systems, clearer module organization.

---

### Day 6-7: Backup Setup ❌ NOT STARTED (HIGH PRIORITY)

#### Day 6: Manual Backup Test

- [ ] SSH into Synology: `ssh admin@synology.local`
- [ ] Create borg user on Synology
- [ ] Create backup directories on Synology
- [ ] Initialize Borg repo: `borg init --encryption=repokey-blake2 borg@synology.local:/volume1/backups/orion`
- [ ] Create test backup of ~/Documents
- [ ] Verify backup: `borg list borg@synology.local:/volume1/backups/orion`
- [ ] Delete test backup if successful
- [ ] Document Borg passphrase in password manager

**Success Metric:** ✅ Manual backup to Synology works

#### Day 7: Automated Backup Module

- [ ] Create `modules/system/optional/services/backup.nix` (from IMPLEMENTATION-GUIDE.md)
- [ ] Add borg-passphrase to secrets.yaml
- [ ] Enable backup on Orion in default.nix
- [ ] Rebuild Orion: `just rebuild-orion`
- [ ] Verify service: `systemctl status borgbackup-job-synology.service`
- [ ] Manually trigger: `systemctl start borgbackup-job-synology.service`
- [ ] Check backup: `borg list borg@synology.local:/volume1/backups/orion`
- [ ] Enable backup on Cortex in default.nix
- [ ] Deploy to Cortex: `just deploy-cortex`
- [ ] Verify Cortex backup service

**Success Metric:** ✅ Automated daily backups configured on both systems

**Status:** NO AUTOMATED BACKUPS - Critical data protection gap!  
**Priority:** P1 (HIGHEST). Estimated 2 hours total.  
**Impact:** Currently no data protection for Orion or Cortex configurations.  
**Resources:** Synology DS-920+ available but unused. See IMPLEMENTATION-GUIDE.md for backup.nix module.

---

## 🟡 Week 2-4: High Priority Enhancements

### Week 2: Documentation & Secrets ✅ COMPLETED

- [x] Review `COMPARISON-ANALYSIS.md` fully
- [x] Review `QUICK-WINS.md` fully
- [x] Update PROJECT-OVERVIEW.md with new architecture
- [x] Create `.sops.yaml` with creation rules (see COMPARISON-ANALYSIS.md)
- [x] Add `just rekey` command to justfile
- [x] Documented complete secrets workflow in SECRETS.md
- [x] Test secret rekeying

**Success Metric:** ✅ Secrets management workflow documented and operational

**Status:** Complete with automatic sync via rebuild-pre hook. See SECRETS.md.

---

### Week 3: Complete Cortex Provisioning ✅ COMPLETED

- [x] Install NVIDIA drivers (open kernel modules for Blackwell)
- [x] Install CUDA toolkit (with uvm_disable_hmm=1 workaround)
- [x] Test RTX 5090 functionality (32GB VRAM accessible)
- [x] Install LLM frameworks (Ollama with 6 models)
- [x] Test GPU-accelerated LLM inference (working)
- [x] Document Cortex-specific setup (modules/system/ai-services/)
- [x] Create comprehensive AI services module

**Success Metric:** ✅ Cortex fully operational with RTX 5090 + Ollama

**Status:** Complete. Models loaded: llama3.2:3b, qwen2.5:7b, deepseek-r1:14b, qwen2.5-coder:32b, command-r:35b, mixtral:8x7b.  
**Note:** Open WebUI temporarily disabled due to ctranslate2 build issues on NixOS unstable.

---

### Week 4: YubiKey Integration ❌ NOT STARTED (Optional)

- [ ] Order YubiKey if not already owned
- [ ] Study EmergentMind's `yubikey.nix`
- [ ] Create `modules/system/optional/yubikey.nix`
- [ ] Configure PAM for U2F
- [ ] Register YubiKey on Orion
- [ ] Test: sudo with YubiKey touch
- [ ] Test: SSH with YubiKey
- [ ] Register YubiKey on Cortex
- [ ] Document YubiKey setup process

**Success Metric:** ✅ Touch-based sudo working on both systems

**Status:** Optional security enhancement, not yet implemented.  
**Priority:** Low (enhancement, not critical).  
**Impact:** Adds physical 2FA for sudo and SSH.

---

## 🟢 Month 2-3: Nice to Have

### Example Repositories

Create public example/template repositories so others can use nixos-fleet and adopt a similar NixOS config structure:

- [ ] Create `nixos-fleet-example` repo -- minimal working example showing `lib.mkFleet` usage with 2-3 hosts, fleet-config, Colmena integration, and secrets setup
- [ ] Create `nixos-config-example` repo -- stripped-down reference NixOS config demonstrating the fleet architecture (multi-host, modules, home-manager, sops-nix)
- [ ] Add links from nixos-fleet README to the example repo
- [ ] Consider using `nix flake init -t` templates in nixos-fleet for bootstrapping

### Month 2-3: Medium Priority Improvements

**Custom Library:**
- [ ] Create `lib/` directory structure
- [ ] Implement host-specific helpers
- [ ] Add common configuration functions
- [ ] Update modules to use custom lib
- [ ] Document library functions

**Testing & Validation:**
- [ ] Set up VM testing environment
- [ ] Test impermanence in disposable VM
- [ ] Create automated deployment tests
- [ ] Implement rollback procedures
- [ ] Document testing workflow

**Stable Channel Integration (from m3tam3re):**
- [ ] Add nixpkgs-stable input to flake
- [ ] Create stable-packages overlay
- [ ] Document which services use stable vs unstable
- [ ] Plan to pin production services (Jellyfin, Frigate) to stable
- [ ] Test stable channel integration

---

## 📊 Progress Tracking

### Week 1 Status (Updated: October 29, 2025)

| Day | Task | Status | Notes |
|-----|------|--------|-------|
| 1 | Deployment Safety | ✅ | Scripts created & tested |
| 2 | Deployment Safety | ✅ | Integrated with justfile |
| 3 | Just Automation | ✅ | justfile operational with 20+ commands |
| 4 | Documentation | ✅ | PROJECT-OVERVIEW, ARCHITECTURE comprehensive |
| 4 | Core/Optional Plan | ❌ | Not started (alternative to docs) |
| 5 | Core/Optional Migration | ❌ | Blocked by Day 4 planning |
| 6 | Manual Backup Test | ❌ | HIGH PRIORITY - No backups! |
| 7 | Automated Backups | ❌ | HIGH PRIORITY - No backups! |

**Legend:** ⬜ Not Started | 🟨 In Progress | ✅ Complete | ❌ Not Started/Blocked

**Progress:** 4/7 days completed (~57%). Focus pivoted to documentation (Day 4) instead of Core/Optional planning.

### Blockers & Issues

- [ ] Issue 1: _______________________________
  - Impact: _______________________________
  - Resolution: _______________________________

- [ ] Issue 2: _______________________________
  - Impact: _______________________________
  - Resolution: _______________________________

---

## 🎯 Success Metrics Summary

### Week 1 Goals (Updated October 29, 2025)
- ✅ Zero deployment failures in 5+ attempts
- ✅ All `just` commands working
- ❌ Clear core/optional separation (not started)
- ❌ Automated backups running daily (HIGH PRIORITY)

**Progress:** 50% (2/4 goals). Backups are critical gap!

### Month 1 Goals
- ✅ Complete Cortex provisioning (GPU, CUDA, LLMs)
- ❌ YubiKey integration (optional, not started)
- ✅ Updated documentation (comprehensive)
- ✅ Secrets automation with Just (rebuild-pre hook)

**Progress:** 75% (3/4 goals). Documentation exceeds expectations.

### Month 3 Goals
- ❌ Proxmox server operational
- ❌ Testing infrastructure (pre-commit)
- ❌ Offsite backups (optional)
- ❌ Monitoring stack (optional)

**Progress:** 0% (0/4 goals). Not yet reached Month 3 phase.

---

## 📝 Notes & Learnings

### What Went Well


### What Could Be Improved


### Ideas for Future


---

## 🔗 Quick Reference Links

- [COMPARISON-ANALYSIS.md](./COMPARISON-ANALYSIS.md) - Detailed analysis & recommendations
- [IMPLEMENTATION-GUIDE.md](IMPLEMENTATION-GUIDE.md) - Implementation guides for Week 1
- [PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md) - Your current architecture
- [FLEET-MANAGEMENT.md](./FLEET-MANAGEMENT.md) - Deployment workflows
- [SECRETS.md](./SECRETS.md) - Complete secrets management guide
- [EmergentMind's Config](https://github.com/EmergentMind/nix-config) - Reference implementation
- [EmergentMind's Anatomy Article](https://unmovedcentre.com/posts/anatomy-of-a-nixos-config/) - Core concepts

---

**Last Updated:** ___________  
**Next Review:** ___________

**Remember:** Focus on P0 (Critical) items first. Don't try to do everything at once!
