# Implementation Roadmap (Visual)

```
╔══════════════════════════════════════════════════════════════════════════╗
║                    NIXOS CONFIGURATION IMPROVEMENT ROADMAP               ║
║                                                                          ║
║  From: Unstable deploys, unclear architecture, no backups                ║
║  To:   Production-ready fleet with automated operations                  ║
╚══════════════════════════════════════════════════════════════════════════╝


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WEEK 1: CRITICAL FOUNDATIONS (10 hours) - DO THESE FIRST
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Day 1-2: DEPLOYMENT SAFETY ✅ COMPLETED
┌────────────────────────────────────────────────────────────────┐
│ Status: Scripts created and tested                             │
│                                                                │
│ ✅ scripts/pre-flight.sh    - Validates before deploy          │
│ ✅ scripts/validate.sh      - Confirms after deploy            │
│ ✅ scripts/safe-deploy.sh   - Orchestrates both                │
│                                                                │
│ Remaining: Integrate as default deployment method              │
│ Impact: 90% of deployment failures preventable                 │
└────────────────────────────────────────────────────────────────┘
        ↓
Day 3: JUST AUTOMATION ✅ COMPLETED
┌────────────────────────────────────────────────────────────────┐
│ Status: justfile exists with task automation                   │
│                                                                │
│ ✅ justfile created with rebuild/deploy/check commands         │
│ ✅ Just installed in system packages                           │
│                                                                │
│ Usage:                                                         │
│   ✅ just --list (see all commands)                            │
│   ✅ Consistent workflows, fewer mistakes                      │
│                                                                │
│ Impact: Standardized operations across systems                 │
└────────────────────────────────────────────────────────────────┘
        ↓
Day 4: DOCUMENTATION ✅ COMPLETED | Day 5: CORE/OPTIONAL ❌ NOT STARTED
┌────────────────────────────────────────────────────────────────┐
│ Day 4 Status: Documentation comprehensive and up-to-date       │
│ ✅ docs/PROJECT-OVERVIEW.md updated (Oct 29, 2025)                  │
│ ✅ docs/ARCHITECTURE.md created (500+ lines)                   │
│ ✅ IMPLEMENTATION-GUIDE.md updated with status tracking                  │
│                                                                │
│ Day 5 Status: Core/Optional architecture NOT implemented       │
│ ❌ Module structure still flat (base/hardware/services)        │
│ ❌ Blocked by Day 3 planning (audit needed)                    │
│                                                                │
│ Target Architecture:             Current State:                │
│  modules/system/                 modules/system/               │
│  ├── core/                       ├── base/                     │
│  │   ├── nix.nix                 ├── hardware/                 │
│  │   ├── security.nix            ├── services/                 │
│  │   └── ssh.nix                 └── wayland/                  │
│  ├── optional/                                                 │
│  │   ├── hardware/                                             │
│  │   ├── services/                                             │
│  │   └── wayland/                                              │
│  └── users/                                                    │
│                                                                │
│ Remaining: Audit modules, create MIGRATION-PLAN.md (est 4hrs)  │
│ Impact: Scales to 10+ systems, clarity, consistency            │
└────────────────────────────────────────────────────────────────┘
        ↓
Day 6-7: AUTOMATED BACKUPS ❌ NOT STARTED (HIGH PRIORITY)
┌────────────────────────────────────────────────────────────────┐
│ Status: NO AUTOMATED BACKUPS - Synology DS-920+ unused         │
│                                                                │
│ Current Situation:                                             │
│   ❌ No data protection for either system                      │
│   ❌ Synology available but not configured                     │
│   ❌ Borg not installed or tested                              │
│                                                                │
│ Plan (2 hours estimated):                                      │
│   Day 6: Manual Borg backup to Synology (test)                 │
│   Day 7: Automated module with systemd timer                   │
│                                                                │
│ Target Result:                                                 │
│   ✅ Orion  → Synology (daily, 7d/4w/6m retention)             │
│   ✅ Cortex → Synology (daily, 7d/4w/6m retention)             │
│                                                                │
│ Priority: P1 (HIGHEST) - Critical data protection gap          │
│ Impact: Data protection, disaster recovery                     │
└────────────────────────────────────────────────────────────────┘
        ↓
     ⏳ Week 1 PARTIALLY COMPLETE
        ✅ Deployment safety (scripts created & tested)
        ✅ Just automation (justfile operational)
        ✅ Documentation (comprehensive & accurate)
        ❌ Core/Optional architecture (not started - est 4hrs)
        ❌ Automated backups (not started - HIGH PRIORITY, est 2hrs)


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 WEEK 2-4: HIGH PRIORITY (15 hours)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Week 2: DOCUMENTATION & SECRETS ✅ COMPLETED
┌────────────────────────────────────────────────────────────────┐
│ ✅ docs/PROJECT-OVERVIEW.md updated (Oct 29, 2025)                  │
│ ✅ docs/ARCHITECTURE.md created (comprehensive)                │
│ ✅ .sops.yaml configured with creation rules                   │
│ ✅ `just rekey` automation added to justfile                   │
│ ✅ Secrets workflow documented in SECRETS-*.md files           │
│                                                                │
│ Files: docs/PROJECT-OVERVIEW.md, ARCHITECTURE.md, SECRETS-*.md      │
│ Access: nixos-secrets/ repo with age encryption                │
└────────────────────────────────────────────────────────────────┘

Week 3: COMPLETE CORTEX PROVISIONING ✅ COMPLETED
┌────────────────────────────────────────────────────────────────┐
│ Status: RTX 5090 configured with AI services operational       │
│                                                                │
│ ✅ NVIDIA drivers (open kernel modules for Blackwell)          │
│ ✅ CUDA toolkit (with uvm_disable_hmm=1 workaround)            │
│ ✅ RTX 5090 functionality (32GB VRAM accessible)               │
│ ✅ Ollama with CUDA acceleration                               │
│ ✅ 6 models loaded (llama3.2:3b → mixtral:8x7b)                │
│ ✅ GPU-accelerated inference tested and working                │
│ ✅ modules/system/ai-services documented                       │
│                                                                │
│ Note: Open WebUI disabled temporarily (ctranslate2 build)      │
│ Access: ssh jarvis@192.168.1.7, Ollama API port 11434          │
└────────────────────────────────────────────────────────────────┘

Week 4: YUBIKEY INTEGRATION ❌ NOT STARTED (Optional)
┌────────────────────────────────────────────────────────────────┐
│ Status: Optional security enhancement, not yet implemented     │
│                                                                │
│ Planned Tasks:                                                 │
│   ❌ Configure PAM for U2F                                     │
│   ❌ Register YubiKey on Orion                                 │
│   ❌ Register YubiKey on Cortex                                │
│   ❌ Test: sudo with touch                                     │
│   ❌ Test: SSH with YubiKey                                    │
│   ❌ Test: Git signing with YubiKey                            │
│                                                                │
│ Priority: Low (enhancement, not critical)                      │
└────────────────────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 MONTH 2: ENHANCEMENT (20 hours)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CUSTOM LIBRARY FUNCTIONS
┌────────────────────────────────────────────────────────────────┐
│ Create: lib/custom.nix                                         │
│   - autoImport helper (replaces fileFilter)                    │
│   - Marvel-themed user helpers                                 │
│   - Custom library extensions                                  │
│                                                                │
│ Update: flake.nix to extend lib                                │
│ Use: lib.custom throughout configs                             │
└────────────────────────────────────────────────────────────────┘

TESTING INFRASTRUCTURE
┌────────────────────────────────────────────────────────────────┐
│ Add: pre-commit-hooks to flake inputs                          │
│ Create: checks.nix                                             │
│   - nixfmt (formatting)                                        │
│   - statix (linting)                                           │
│   - deadnix (unused code detection)                            │
│   - shellcheck (script validation)                             │
│                                                                │
│ Set up: Git pre-commit hook                                    │
│ Run: `just check` before every commit                          │
└────────────────────────────────────────────────────────────────┘

VPN REMOTE ACCESS
┌────────────────────────────────────────────────────────────────┐
│ Evaluate: Headscale for remote access                          │
│ Deploy: VPN server on Proxmox (or Orion)                       │
│ Configure: All systems as VPN clients                          │
│ Test: Remote access from outside network                       │
└────────────────────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 MONTH 3: HOMELAB EXPANSION (30+ hours)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

FLEET MANAGEMENT EXPANSION ❌ NOT STARTED (3-4 hours)
┌────────────────────────────────────────────────────────────────┐
│ Status: Using deploy-rs, planning Colmena migration            │
│                                                                │
│ Current Tools:                                                 │
│   ✅ deploy-rs - Sequential deployments                        │
│   ✅ just - Task automation                                    │
│   ✅ fleet.sh - System discovery and management                │
│   ✅ safe-deploy.sh - Pre/post-flight checks                   │
│                                                                │
│ Planned Migration to Colmena (when ready):                     │
│   ❌ Parallel deployment to multiple systems                   │
│   ❌ Tag-based targeting (@server, @ai, @homelab)              │
│   ❌ Simpler fleet configuration                               │
│   ❌ Fleet-wide health checks and monitoring                   │
│                                                                │
│ Prerequisites:                                                 │
│   - Colmena supports current flake syntax                      │
│   - Managing 5+ systems (worth the migration effort)           │
│   - Need parallel deployment time savings                      │
│                                                                │
│ Implementation:                                                │
│   1. Add Colmena to flake inputs (30 min)                      │
│   2. Configure colmena output with tags (1 hour)               │
│   3. Test parallel deployment (1 hour)                         │
│   4. Update justfile commands (30 min)                         │
│   5. Update fleet.sh to use Colmena (1 hour)                   │
│                                                                │
│ Benefits:                                                      │
│   - Deploy to 5+ systems in ~5 minutes (vs 25+ sequential)     │
│   - Tag-based updates (update @server, @homelab, etc.)         │
│   - Simplified fleet operations                                │
│   - Fleet-wide command execution (colmena exec)                │
│                                                                │
│ Reference: docs/FLEET-FUTURE.md                                │
│ Priority: Medium (wait until 5+ systems)                       │
└────────────────────────────────────────────────────────────────┘

EXPANDED JUST AUTOMATION ✅ IN PROGRESS (Ongoing)
┌────────────────────────────────────────────────────────────────┐
│ Status: Basic justfile operational, expansion planned          │
│                                                                │
│ Current Commands:                                              │
│   ✅ just deploy-cortex (with safety checks)                   │
│   ✅ just rebuild-orion (local rebuild)                        │
│   ✅ just update-secrets (automatic sync)                      │
│   ✅ just check-cortex (pre-flight)                            │
│   ✅ just rekey (secrets management)                           │
│                                                                │
│ Planned Expansions:                                            │
│   ❌ just deploy-all (when Colmena added)                      │
│   ❌ just fleet-status (health check all systems)              │
│   ❌ just fleet-uptime (uptime across fleet)                   │
│   ❌ just backup-all (trigger backups on all systems)          │
│   ❌ just monitor (open Grafana dashboard - Month 4+)          │
│                                                                │
│ Priority: Low (incremental improvement)                        │
└────────────────────────────────────────────────────────────────┘

PROXMOX SERVER
┌────────────────────────────────────────────────────────────────┐
│ Plan: Server specs, disk layout                                │
│ Build: Physical server                                         │
│ Create: systems/proxmox/ config                                │
│ Bootstrap: With your new safe-deploy.sh                        │
│ Deploy: `just deploy-proxmox`                                  │
│ Validate: All services running                                 │
└────────────────────────────────────────────────────────────────┘

FRIGATE NVR (on Proxmox VM)
┌────────────────────────────────────────────────────────────────┐
│ Create: VM for Frigate                                         │
│ Configure: Camera streams                                      │
│ Set up: Motion detection, recording                            │
│ Integrate: With Home Assistant                                 │
└────────────────────────────────────────────────────────────────┘

JELLYFIN MEDIA SERVER (on Proxmox VM)
┌────────────────────────────────────────────────────────────────┐
│ Create: VM for Jellyfin                                        │
│ Configure: Media libraries                                     │
│ Set up: Hardware transcoding                                   │
│ Test: Streaming to devices                                     │
└────────────────────────────────────────────────────────────────┘

HOME ASSISTANT (on Proxmox VM)
┌────────────────────────────────────────────────────────────────┐
│ Create: VM for Home Assistant                                  │
│ Integrate: Frigate cameras                                     │
│ Configure: Automations                                         │
│ Set up: Dashboard                                              │
└────────────────────────────────────────────────────────────────┘

         ↓
     YOUR FLEET
┌────────────────────────────────────────────────────────────────┐
│ ✅ Orion       - Laptop (Dev workstation)                      │
│ ✅ Cortex      - AI rig (LLM inference, gaming)                │
│ ✅ Proxmox     - Homelab server                                │
│   ├── Frigate    (NVR)                                         │
│   ├── Jellyfin   (Media)                                       │
│   └── Home Assistant (Automation)                              │
│ ✅ Synology    - Backup target (DS-920+)                       │
└────────────────────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 MONTH 4+: ADVANCED (Optional)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

MONITORING STACK
┌────────────────────────────────────────────────────────────────┐
│ Deploy: Prometheus + Grafana                                   │
│ Monitor:                                                       │
│   - System metrics (CPU, RAM, disk)                            │
│   - GPU usage (RTX 5090)                                       │
│   - Backup success/failure                                     │
│   - Deployment status                                          │
│                                                                │
│ Alert: Slack/Discord when issues detected                      │
└────────────────────────────────────────────────────────────────┘

IMPERMANENCE (EmergentMind's Stage 8)
┌────────────────────────────────────────────────────────────────┐
│ Concept: Root filesystem ephemeral, only /persist survives     │
│ Benefits: Clean state, forced intentional persistence          │
│ Warning: Complex to implement correctly                        │
│ Status: Not urgent, wait until stable foundation               │
└────────────────────────────────────────────────────────────────┘

SECURE BOOT (Lanzaboote)
┌────────────────────────────────────────────────────────────────┐
│ Concept: UEFI Secure Boot for NixOS                            │
│ Benefits: Prevents bootkit malware                             │
│ Status: Advanced feature, Month 6+                             │
└────────────────────────────────────────────────────────────────┘

OFFSITE BACKUPS
┌────────────────────────────────────────────────────────────────┐
│ Set up: Cloud backup (Backblaze B2 or Wasabi)                  │
│ Schedule: Monthly encrypted uploads                            │
│ Retention: 1 year                                              │
│ Cost: ~$5-10/month for 500GB                                   │
└────────────────────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 PROGRESS MILESTONES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

┌───────────────┬────────────────────────────────────────────────┐
│   Milestone   │              Success Criteria                  │
├───────────────┼────────────────────────────────────────────────┤
│ Week 1 ⏳     │ ✅ 5+ successful deploys without SSH loss      │
│               │ ✅ Using Just for all operations               │
│               │ ❌ Core/optional architecture (not started)    │
│               │ ❌ Daily backups to Synology (HIGH PRIORITY)   │
├───────────────┼────────────────────────────────────────────────┤
│ Month 1 ⏳    │ ✅ Cortex fully provisioned (GPU, CUDA, LLMs)  │
│               │ ❌ YubiKey integration (optional, not started) │
│               │ ✅ Documentation updated throughout            │
│               │ ✅ Secrets automation with Just                │
├───────────────┼────────────────────────────────────────────────┤
│ Month 3 ❌    │ ❌ Proxmox server operational                  │
│               │ ❌ Frigate NVR deployed                        │
│               │ ❌ Jellyfin media server running               │
│               │ ❌ Home Assistant integrated                   │
│               │ ❌ Full fleet managed with Just                │
├───────────────┼────────────────────────────────────────────────┤
│ Month 6 ❌    │ ❌ Monitoring stack (Prometheus, Grafana)      │
│               │ ❌ Testing infrastructure (CI/CD)              │
│               │ ❌ Offsite backups to cloud                    │
│               │ ❌ Production-grade infrastructure             │
└───────────────┴────────────────────────────────────────────────┘


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 KEY PRINCIPLES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. START SMALL
   • Focus on P0 (Critical) items first
   • Don't try to do everything at once
   • Validate after each change

2. BUILD HABITS
   • Use `just` for all operations
   • Run pre-flight before every deploy
   • Commit before risky changes
   • Update docs/TODO-CHECKLIST.md daily

3. DOCUMENT LEARNINGS
   • What worked well?
   • What was harder than expected?
   • What would you do differently?
   • Share with community (optional)

4. ITERATE & IMPROVE
   • Your config will evolve
   • EmergentMind took 2 years, 11 stages
   • Progress over perfection
   • Enjoy the journey!


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 RESOURCES
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📖 Your Documentation
   • COMPARISON-ANALYSIS.md   - Detailed analysis & recommendations
   • IMPLEMENTATION-GUIDE.md            - Week 1 implementation guide
   • docs/TODO-CHECKLIST.md        - Progress tracker
   • ANALYSIS-SUMMARY.md      - This summary

📖 EmergentMind's Resources
   • GitHub: github.com/EmergentMind/nix-config
   • Website: unmovedcentre.com
   • Anatomy Article: unmovedcentre.com/posts/anatomy-of-a-nixos-config
   • YouTube: youtube.com/@Emergent_Mind

📖 Learning Resources
   • VimJoyer: youtube.com/@vimjoyer (excellent tutorials)
   • Misterio77's Starter: github.com/Misterio77/nix-starter-configs
   • NixOS Wiki: nixos.wiki
   • NixOS Discourse: discourse.nixos.org


━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

 🚀 CURRENT STATUS (October 29, 2025)

    Week 1: ⏳ PARTIALLY COMPLETE
    ✅ Deployment Safety (Day 1-2) - Scripts created & tested
    ✅ Just Automation (Day 3) - justfile operational  
    ✅ Documentation (Day 4) - Comprehensive & accurate
    ❌ Core/Optional Architecture (Day 5) - Not started
    ❌ Automated Backups (Day 6-7) - HIGH PRIORITY

 🎯 NEXT PRIORITIES:

    1. P1 (CRITICAL): Automated Backups - 2 hours
       → No data protection currently! Synology available but unused
       → See IMPLEMENTATION-GUIDE.md Day 6-7 for implementation

    2. P2 (HIGH): Core/Optional Architecture - 4 hours  
       → Blocked by Day 3 planning (audit + MIGRATION-PLAN.md)
       → Enables scaling to 10+ systems

    3. P3 (MEDIUM): Integrate Pre-flight Scripts - 1 hour
       → Make safe-deploy.sh the default deployment method

 Remember: Progress over perfection. Focus on P1 first! 🎯

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
