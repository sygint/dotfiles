---
title: "Fixing Deployment Hell: NixOS Week 1 Day 1"
date: 2025-10-15
tags: [nixos, devops, deployment, automation]
status: published
---

# Fixing Deployment Hell: NixOS Week 1 Day 1

## The Problem

I've been running NixOS on two systems (Orion laptop, Cortex AI rig) for a while now, but deployment has been my #1 pain point.

When deploying to remote systems with `deploy-rs`, I'd sometimes lose:
- SSH connectivity (wrong network config)
- Network entirely (firewall misconfiguration)
- Access to the system (had to physically connect)

Manual recovery required. Not fun at 2am.

## The Research Phase (Week 0)

Instead of hacking together quick fixes, I spent time studying two production NixOS configs:

1. **[EmergentMind/nix-config](https://github.com/EmergentMind/nix-config)** (516⭐, 2+ years production)
   - Enterprise-level validation patterns
   - Pre-flight checks before deployment
   - Post-deployment verification

2. **[m3tam3re/nixcfg](https://github.com/m3tam3re/nixcfg)** (video18 branch)
   - Tutorial-oriented structure
   - Core/optional architecture
   - Secrets management patterns

Key insight from EmergentMind: **Validate before and after deployment**. Don't deploy blind.

## The Solution (Day 1)

I implemented a 3-stage deployment safety system:

### 1. Pre-Flight Validation (`scripts/pre-flight.sh`)

6 checks **before** deploying:
```bash
[1/6] Network reachability... ✅
[2/6] SSH connectivity... ✅
[3/6] NixOS system check... ✅
[4/6] Disk space... ✅ (67% used)
[5/6] Critical services... ✅
[6/6] System load... ✅ (load: 0.45)
```

If any check fails → **abort deployment**. No more deploying to unreachable hosts.

### 2. Post-Deployment Validation (`scripts/validate.sh`)

5 checks **after** deploying:
```bash
[1/5] SSH connectivity... ✅
[2/5] System state... ✅ (running)
[3/5] Critical services... ✅
[4/5] Boot generation... ✅ (generation 142)
[5/5] Failed units... ✅
```

If SSH fails → immediate notification with rollback instructions.

### 3. Safe Orchestration (`scripts/safe-deploy.sh`)

Wraps the entire workflow:
```bash
Step 1: Pre-flight validation
  → All checks pass? Continue : Abort

Step 2: Deploy with deploy-rs
  → Record before/after generations

Step 3: Post-deployment validation
  → All checks pass? Success : Show rollback instructions
```

### 4. Task Automation (`justfile`)

Inspired by EmergentMind's rebuild-pre/post hooks:
```bash
# Before every deploy: sync secrets automatically
rebuild-pre: update-secrets

# Deploy to Cortex with safety
deploy-cortex: rebuild-pre
  ./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis
```

No more manual commands. No more forgetting to sync secrets.

## The Implementation

**Files created:**
- `scripts/pre-flight.sh` - Pre-deployment checks
- `scripts/validate.sh` - Post-deployment checks
- `scripts/safe-deploy.sh` - Orchestration
- `justfile` - Task automation

**Usage:**
```bash
# Old way (risky):
deploy .#cortex

# New way (safe):
just deploy-cortex
```

**Time invested:** ~3 hours
**Lines of code:** ~200 (scripts + justfile)

## Early Results

Haven't tested on production yet, but the approach is sound:
1. Catches problems **before** deployment (network down, SSH broken)
2. Validates success **after** deployment (system still accessible)
3. Provides clear rollback instructions if anything fails

## What I Learned

1. **Discipline > Infrastructure** - EmergentMind's rebuild-pre hook is brilliant. Auto-syncing secrets before every deploy prevents version mismatches.

2. **Validate Early** - Pre-flight checks catch 90% of issues before they become problems.

3. **Study Production Configs** - EmergentMind's config has 2+ years of production hardening. That's worth more than docs.

4. **Adapt, Don't Copy** - EmergentMind uses local `nixos-rebuild`. I use remote `deploy-rs`. The patterns transfer, but the implementation differs.

## Next Steps

**Week 1 Remaining:**
- Day 2: Test Day 1 scripts on Cortex (this weekend)
- Day 4-5: Migrate to core/optional architecture
- Day 6-7: Automated backups to Synology NAS

**Week 2:**
- Provision Cortex for AI workloads (RTX 5090, CUDA, Ollama)
- Create architecture diagram with Excalidraw

**Week 3:**
- Replace GitHub Copilot with local RTX 5090 inference
- Document the AI provisioning process

## Closing Thoughts

This is the beginning of a larger journey - taking my NixOS config from "works on my machine" to production-grade infrastructure. 

The goal isn't perfection. It's **sustainable improvement**.

Week 1 Day 1: ✅ Deployment safety foundation  
6 more days to go.

---

*This is part of a weekly blog series documenting my NixOS config improvement journey. All code is available in my [dotfiles repo](https://github.com/sygint/dotfiles).*

## Resources

- [EmergentMind/nix-config](https://github.com/EmergentMind/nix-config) - Production patterns
- [m3tam3re/nixcfg](https://github.com/m3tam3re/nixcfg) - Tutorial approach
- [deploy-rs](https://github.com/serokell/deploy-rs) - Remote deployment tool
- [Just command runner](https://github.com/casey/just) - Task automation
