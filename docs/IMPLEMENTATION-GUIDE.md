# QUICK-WINS Implementation Guide

**Status:** Partially implemented - Core/Optional architecture and automated backups remain

**Time Investment:** ~4-5 hours remaining (Core/Optional migration + backups)  
**Impact:** Scalable architecture for 10+ systems, automated data protection

---

## ✅ Completed Tasks

- ✅ **Day 1-2: Deployment Safety** - Scripts created (pre-flight.sh, validate.sh, safe-deploy.sh)
- ✅ **Day 2: Just Automation** - justfile exists with task automation
- ✅ **Day 4: Documentation** - docs/PROJECT-OVERVIEW.md and ARCHITECTURE.md comprehensive

## ⚠️ Remaining High-Value Tasks

### Priority 1: Automated Backups (2 hours)
- ❌ **Day 6-7: Backup Setup** - Synology available, Borg not configured
- **Impact:** No data protection - CRITICAL
- **Next:** Follow Day 6-7 guide below to create backup.nix module

### Priority 2: Core/Optional Architecture (4 hours)  
- ❌ **Day 3-5: Module Reorganization** - All modules currently flat/optional
- **Impact:** Doesn't scale beyond 2-3 systems, repetitive configuration
- **Next:** Follow Day 3-5 guide below to create core/optional structure

### Priority 3: Deployment Integration
- ⚠️ **Scripts exist but not primary workflow** - safe-deploy.sh not default
- **Impact:** Still possible to deploy without safety checks
- **Next:** Make safe-deploy.sh the default deployment method

---

## ✅ Day 1: Deployment Safety (COMPLETED)

**Status:** Scripts exist in `scripts/` directory

**What was implemented:**
- ✅ `scripts/pre-flight.sh` - Pre-deployment validation
- ✅ `scripts/validate.sh` - Post-deployment checks  
- ✅ `scripts/safe-deploy.sh` - Orchestration wrapper

**Remaining work:** Integration into main deployment workflow (use safe-deploy.sh instead of direct deploy-rs)

### 1. Pre-flight Validation Script (Reference)

```bash
#!/usr/bin/env bash
# scripts/pre-flight.sh
# Usage: ./scripts/pre-flight.sh cortex 192.168.1.7 jarvis

set -euo pipefail

HOST=$1
IP=$2
USER=$3

echo "🔍 Pre-flight checks for $HOST ($IP)..."
echo ""

# Check 1: Network reachability
echo -n "  [1/6] Network reachability... "
if ping -c 3 -W 2 $IP > /dev/null 2>&1; then
  echo "✅"
else
  echo "❌ FAIL: Host unreachable"
  exit 1
fi

# Check 2: SSH connectivity
echo -n "  [2/6] SSH connectivity... "
if timeout 5 ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no $USER@$IP "echo 'OK'" > /dev/null 2>&1; then
  echo "✅"
else
  echo "❌ FAIL: SSH connection failed"
  echo "    Check: SSH daemon running? Correct user/key?"
  exit 1
fi

# Check 3: NixOS system
echo -n "  [3/6] NixOS system check... "
if ssh $USER@$IP "[ -f /etc/NIXOS ]" 2>/dev/null; then
  echo "✅"
else
  echo "❌ FAIL: Not a NixOS system"
  exit 1
fi

# Check 4: Disk space
echo -n "  [4/6] Disk space... "
DISK_USAGE=$(ssh $USER@$IP "df -h / | tail -1 | awk '{print \$5}' | sed 's/%//'" 2>/dev/null)
if [ $DISK_USAGE -lt 90 ]; then
  echo "✅ (${DISK_USAGE}% used)"
else
  echo "⚠️  WARN: Disk usage at ${DISK_USAGE}%"
  echo "    Consider cleaning up before deploy"
fi

# Check 5: Critical services
echo -n "  [5/6] Critical services... "
FAILED_SERVICES=0
for svc in sshd NetworkManager; do
  if ! ssh $USER@$IP "systemctl is-active $svc" > /dev/null 2>&1; then
    echo ""
    echo "    ❌ $svc is not active"
    FAILED_SERVICES=1
  fi
done
if [ $FAILED_SERVICES -eq 0 ]; then
  echo "✅"
else
  exit 1
fi

# Check 6: System load
echo -n "  [6/6] System load... "
LOAD=$(ssh $USER@$IP "uptime | awk -F'load average:' '{print \$2}' | awk '{print \$1}' | sed 's/,//'" 2>/dev/null)
echo "✅ (load: $LOAD)"

echo ""
echo "✅ All pre-flight checks passed!"
echo "   Ready to deploy to $HOST"
```

### 2. Create Post-deployment Validation Script

```bash
#!/usr/bin/env bash
# scripts/validate.sh
# Usage: ./scripts/validate.sh cortex 192.168.1.7 jarvis

set -euo pipefail

HOST=$1
IP=$2
USER=$3

echo "🔍 Validating deployment to $HOST..."
echo ""

# Wait a moment for services to settle
sleep 5

# Check 1: SSH still works
echo -n "  [1/5] SSH connectivity... "
if timeout 10 ssh -o ConnectTimeout=10 $USER@$IP "echo 'OK'" > /dev/null 2>&1; then
  echo "✅"
else
  echo "❌ CRITICAL: Lost SSH access!"
  echo "    Manual intervention required"
  exit 1
fi

# Check 2: System is running
echo -n "  [2/5] System state... "
SYS_STATE=$(ssh $USER@$IP "systemctl is-system-running" 2>/dev/null || echo "unknown")
if echo "$SYS_STATE" | grep -qE "running|degraded"; then
  echo "✅ ($SYS_STATE)"
else
  echo "⚠️  WARN: System state is $SYS_STATE"
fi

# Check 3: Critical services
echo -n "  [3/5] Critical services... "
FAILED=0
for svc in sshd NetworkManager; do
  if ! ssh $USER@$IP "systemctl is-active $svc" > /dev/null 2>&1; then
    echo ""
    echo "    ❌ $svc is not active"
    FAILED=1
  fi
done
if [ $FAILED -eq 0 ]; then
  echo "✅"
else
  echo "    Some services failed - check systemctl status"
fi

# Check 4: Boot generation changed
echo -n "  [4/5] Boot generation... "
CURRENT_GEN=$(ssh $USER@$IP "readlink /run/current-system | grep -oP 'system-\K[0-9]+'" 2>/dev/null)
BOOTED_GEN=$(ssh $USER@$IP "readlink /run/booted-system | grep -oP 'system-\K[0-9]+'" 2>/dev/null)
if [ "$CURRENT_GEN" = "$BOOTED_GEN" ]; then
  echo "✅ (generation $CURRENT_GEN)"
else
  echo "⚠️  Current: $CURRENT_GEN, Booted: $BOOTED_GEN (reboot pending)"
fi

# Check 5: No failed units
echo -n "  [5/5] Failed units... "
FAILED_COUNT=$(ssh $USER@$IP "systemctl list-units --state=failed --no-legend | wc -l" 2>/dev/null)
if [ "$FAILED_COUNT" -eq 0 ]; then
  echo "✅"
else
  echo "⚠️  $FAILED_COUNT failed units"
  ssh $USER@$IP "systemctl list-units --state=failed"
fi

echo ""
if [ $FAILED -eq 0 ]; then
  echo "✅ Validation passed!"
else
  echo "⚠️  Validation completed with warnings"
  exit 1
fi
```

### 3. Update Deployment Workflow

**Before:** (risky)
```bash
deploy-rs .#cortex
```

**After:** (safe)
```bash
#!/usr/bin/env bash
# scripts/safe-deploy.sh
# Usage: ./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis

set -euo pipefail

HOST=$1
IP=$2
USER=$3

echo "🚀 Safe deployment to $HOST"
echo ""

# Step 1: Pre-flight checks
./scripts/pre-flight.sh $HOST $IP $USER || {
  echo "❌ Pre-flight checks failed. Aborting."
  exit 1
}

echo ""
echo "📦 Starting deployment..."

# Step 2: Deploy with rollback on error
if deploy-rs --skip-checks false --rollback-on-error .#$HOST; then
  echo "✅ Deploy completed successfully"
else
  echo "❌ Deploy failed"
  exit 1
fi

echo ""

# Step 3: Validate deployment
./scripts/validate.sh $HOST $IP $USER || {
  echo "❌ Validation failed!"
  echo ""
  echo "⚠️  ROLLBACK RECOMMENDED"
  echo "    Run: deploy-rs --rollback .#$HOST"
  exit 1
}

echo ""
echo "🎉 Deployment successful and validated!"
```

### 4. Make Scripts Executable

```bash
chmod +x scripts/{pre-flight,validate,safe-deploy}.sh
```

### 5. Test the Workflow

```bash
# Test pre-flight checks
./scripts/pre-flight.sh cortex 192.168.1.7 jarvis

# If that passes, do a safe deploy
./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis
```

---

## ✅ Day 2: Just Automation (COMPLETED)

**Status:** `justfile` exists with task automation

**What was implemented:**
- ✅ justfile created with common commands
- ✅ Just installed in system packages

**Usage:** See `just --list` for available commands

### Goal (Reference)

**Why:** Consistent commands, automatic secrets sync, fewer mistakes

### 1. Install Just

```nix
# Add to modules/system/core/default.nix or orion/default.nix
environment.systemPackages = with pkgs; [
  just
];
```

### 2. Create Enhanced Justfile with Secrets Sync

**Key Addition:** Automatic secrets sync via `rebuild-pre` hook (EmergentMind's pattern)

```justfile
# justfile - Task automation for NixOS config
# Run `just` to see all commands

# Default: show available commands
default:
  @just --list

# ====== PRE/POST HOOKS (EmergentMind Pattern) ======

# Run BEFORE every rebuild/deploy - syncs secrets automatically
rebuild-pre: update-secrets
  @git add --intent-to-add .

# Run AFTER rebuild - validate sops is working
rebuild-post:
  @echo "✅ Rebuild complete"
  @systemctl --user is-active sops-nix.service > /dev/null && echo "✅ sops-nix active" || echo "⚠️  sops-nix check manually"

# Sync secrets from separate repo (HYBRID APPROACH)
update-secrets:
  @echo "🔄 Syncing secrets..."
  @(cd ../nixos-secrets && git pull) || true
  @nix flake update nixos-secrets --timeout 5
  @echo "✅ Secrets synced"

# ====== LOCAL OPERATIONS ======

# Rebuild Orion (laptop) with pre/post hooks
rebuild-orion: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#orion switch

# Rebuild Cortex (AI rig) - if running locally on Cortex
rebuild-cortex: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#cortex switch

# Rebuild with trace for debugging
rebuild-trace HOST: rebuild-pre && rebuild-post
  sudo nixos-rebuild --flake .#{{HOST}} --show-trace switch

# ====== UPDATE COMMANDS ======

# Update all flake inputs
update:
  nix flake update

# Update specific input
update-input INPUT:
  nix flake update {{INPUT}}

# Update + rebuild Orion
update-orion: update
  just rebuild-orion

# Update + deploy to Cortex
update-cortex: update rebuild-pre
  just deploy-cortex

# ====== REMOTE OPERATIONS ======

# Deploy to Cortex (with safety checks + secrets sync)
deploy-cortex: rebuild-pre
  ./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis

# Pre-flight checks only (no deploy)
check-cortex:
  ./scripts/pre-flight.sh cortex 192.168.1.7 jarvis

# Validate Cortex (post-deploy check)
validate-cortex:
  ./scripts/validate.sh cortex 192.168.1.7 jarvis

# SSH into Cortex
ssh-cortex:
  ssh jarvis@192.168.1.7

# Sync configs to remote host (without building)
sync-cortex:
  rsync -av --exclude='.git' --exclude='result' --exclude='*.md' \
    . jarvis@192.168.1.7:~/.config/nixos

# ====== SECRETS MANAGEMENT ======

# Edit secrets
edit-secrets:
  sops ../nixos-secrets/secrets.yaml

# Rekey all secrets (after adding new host/user keys)
rekey:
  cd ../nixos-secrets && \
  for file in $(ls *.yaml); do sops updatekeys -y $$file; done

# ====== FLEET MANAGEMENT ======

# Fleet status (your custom script)
fleet-status:
  ./scripts/fleet.sh status

# Fleet deploy (when you have multiple systems)
fleet-deploy HOSTS:
  ./scripts/fleet.sh deploy {{HOSTS}}

# ====== UTILITIES ======

# Check flake (validate all configs)
check:
  nix flake check --show-trace

# Format all Nix files
fmt:
  nix fmt

# Git status with context
status:
  @git status
  @echo ""
  @echo "📦 Current Generation:"
  @readlink /run/current-system | grep -oP 'system-\K[0-9]+'
  @echo ""
  @echo "📦 Flake Inputs:"
  @nix flake metadata | grep -A 10 "Inputs:"

# Show disk usage
disk:
  @df -h / /home | grep -v tmpfs

# Show recent builds
generations:
  sudo nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -10

# Clean old generations (keep last 5)
clean:
  sudo nix-collect-garbage --delete-older-than 30d
  sudo nixos-rebuild boot --flake .#$(hostname)
```

### 3. Test Just Commands

```bash
# See all commands
just

# Rebuild Orion (secrets auto-sync before build)
just rebuild-orion

# Update flake + deploy to Cortex (secrets auto-sync)
just update-cortex

# Manual secrets sync (usually automatic)
just update-secrets

# Check Cortex before deploying
just check-cortex
```

### 4. Why This Approach Works

**Hybrid Secrets Strategy (Current - Recommended for 2-3 hosts):**
- ✅ Keeps your `git+file:../nixos-secrets` (local repo, simple)
- ✅ Adds automatic sync via `rebuild-pre` hook (EmergentMind's discipline)
- ✅ Ensures secrets always current before ANY deploy
- ✅ No manual steps to forget
- ✅ Works perfectly for single-admin, 2-3 host setup

**How it works:**
1. You run `just update-cortex` or `just deploy-cortex`
2. `rebuild-pre` hook automatically runs first
3. Secrets repo pulls latest changes
4. `nixos-secrets` flake input updated
5. Build includes current secrets
6. Deploy sends entire closure (with secrets) to Cortex

**Future Enhancement (Phase 3 - 5+ hosts):**
When you reach homelab scale (Proxmox, Frigate, Jellyfin, etc.), consider:
```nix
# Move to remote git repo
nix-secrets = {
  url = "git+ssh://git@homelab.local/nix-secrets.git?shallow=1";
  inputs = { };
};
```

Benefits of remote repo (later):
- Atomic rollbacks (secrets version tied to flake.lock)
- Multi-location management
- Team collaboration
- Better disaster recovery

**But for now:** Local repo + automatic sync = simpler and sufficient

---

## ❌ Day 3: Core/Optional Planning (NOT STARTED)

**Status:** Architecture not implemented - all modules still in flat structure

**Why this matters:**
- Current: All modules optional, explicit enables everywhere
- Goal: Core modules auto-imported on all systems (SSH, security, nix settings)
- Benefit: Scales to 10+ systems without repeating base configuration

### 1. Audit Current Modules

Create a file `MIGRATION-PLAN.md`:

```markdown
# Core/Optional Migration Plan

## Current Modules Audit

### System Modules (modules/system/)

**CORE (Universal on ALL systems):**
- [ ] base/nix.nix - Flakes, garbage collection
- [ ] base/security.nix - fail2ban, auditd, sysctl
- [ ] services/ssh.nix - SSH daemon (if you have this)
- [ ] User account: syg/jarvis

**OPTIONAL (Selective per host):**
- [ ] hardware/bluetooth.nix
- [ ] hardware/audio.nix
- [ ] hardware/networking.nix
- [ ] services/mullvad.nix
- [ ] services/syncthing.nix
- [ ] services/virtualization.nix
- [ ] services/containerization.nix
- [ ] services/printing.nix
- [ ] windowManagers/hyprland.nix
- [ ] displayServers/wayland.nix

### Home Modules (modules/home/programs/)

**CORE (Universal for syg/jarvis):**
- [ ] git.nix
- [ ] zsh.nix
- [ ] btop.nix (basic monitoring)

**OPTIONAL (Selective):**
- [ ] brave.nix
- [ ] librewolf.nix
- [ ] vscode.nix
- [ ] kitty.nix
- [ ] hyprland.nix (desktop-only)
- [ ] hyprpanel.nix (desktop-only)
- [ ] waybar.nix (desktop-only)
- [ ] devenv.nix
- [ ] protonmail-bridge.nix
- [ ] mullvad.nix
- [ ] screenshots.nix

## Migration Steps (Do on Day 5)

1. Create directories:
   ```bash
   mkdir -p modules/system/{core,optional,users}
   mkdir -p modules/home/{core,optional}
   ```

2. Move core system configs:
   ```bash
   mv modules/system/base/* modules/system/core/
   ```

3. Move optional system configs:
   ```bash
   mv modules/system/{hardware,services,programs,windowManagers,displayServers} modules/system/optional/
   ```

4. Create core/default.nix:
   ```nix
   # modules/system/core/default.nix
   {
     imports = [
       ./nix.nix
       ./security.nix
       # Add more core modules as identified
     ];
   }
   ```

5. Update host imports:
   ```nix
   # systems/orion/default.nix
   imports = [
     ./hardware.nix
     ../../modules/system/core  # Auto-imports everything in core
     ../../modules/system/optional/hardware/bluetooth.nix
     ../../modules/system/optional/services/syncthing.nix
     # etc.
   ];
   ```
```

---

## ✅ Day 4: Documentation Updates (COMPLETED)

**Status:** Documentation comprehensive and up-to-date

**What was completed:**
- ✅ docs/PROJECT-OVERVIEW.md updated (October 29, 2025)
- ✅ docs/ARCHITECTURE.md created (comprehensive module documentation)
- ✅ Known Issues section accurate and prioritized
- ✅ Current Status & Roadmap section added

### Reference (Original Goals)

### 1. Update README.md

Add to "Common Tasks" section:

```markdown
## Common Tasks

### Using Just (Recommended)

```bash
# See all available commands
just

# Local operations
just rebuild-orion          # Rebuild Orion locally
just rebuild-cortex         # Rebuild Cortex locally
just update                 # Update flake inputs

# Remote operations
just deploy-cortex          # Deploy to Cortex with safety checks
just ssh-cortex            # SSH into Cortex
just sync-cortex           # Sync configs only (no build)

# Validation
just check-cortex          # Pre-flight checks before deploy
just validate-cortex       # Validate after deploy
just check                 # Flake check

# Fleet management
just fleet-status          # Check all systems
```

### Manual Commands (if Just not available)

[Keep existing content but mark as "Legacy"]
```

### 2. Update FLEET-MANAGEMENT.md

Add new section at the top:

```markdown
## Safe Deployment Workflow

**ALWAYS use this workflow for remote deployments:**

1. **Pre-flight Checks**
   ```bash
   just check-cortex
   # or: ./scripts/pre-flight.sh cortex 192.168.1.7 jarvis
   ```

2. **Commit Current State** (rollback point)
   ```bash
   git add -A
   git commit -m "pre-deploy snapshot: $(date +%Y%m%d-%H%M)"
   ```

3. **Deploy with Safety**
   ```bash
   just deploy-cortex
   # or: ./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis
   ```

4. **Validation** (automatic in safe-deploy.sh)
   - If validation fails, rollback is suggested
   - Follow on-screen instructions

**Never skip pre-flight checks!** They've prevented countless SSH lockouts.
```

---

## ❌ Day 5: Core/Optional Migration (NOT STARTED)

**Status:** Depends on Day 3 planning - not implemented

**Blockers:**
- Need to complete Day 3 module audit first
- Requires MIGRATION-PLAN.md creation
- Estimated time: 2-3 hours once planning done

### 1. Execute Migration Plan (Pending Day 3)

Follow the steps in `MIGRATION-PLAN.md` created on Day 3.

### 2. Test Both Systems

```bash
# Test Orion rebuild
just rebuild-orion

# Test Cortex deploy
just deploy-cortex
```

### 3. Verify Everything Works

```bash
# Check all services on Orion
systemctl --failed

# Check all services on Cortex (remotely)
just ssh-cortex
systemctl --failed
```

---

## ❌ Day 6-7: Backup Setup (NOT STARTED)

**Status:** No automated backups configured

**Current situation:**
- ❌ Synology NAS available but not integrated
- ❌ No Borg backup module created
- ❌ No automated backup schedules

**Impact:** No automated data protection (HIGH PRIORITY)

**Estimated time:** 2 hours to implement

### 1. Install Borg on Synology

```bash
# SSH into Synology
ssh admin@synology.local  # or your Synology IP

# Create borg user
sudo useradd -m borg
sudo passwd borg  # Set a password

# Create backup directories
sudo mkdir -p /volume1/backups/{orion,cortex}
sudo chown -R borg:borg /volume1/backups
```

### 2. Test Manual Backup

```bash
# On Orion, initialize repo
borg init --encryption=repokey-blake2 borg@synology.local:/volume1/backups/orion

# Create test backup
borg create borg@synology.local:/volume1/backups/orion::test-$(date +%Y%m%d) \
  ~/Documents \
  ~/Pictures \
  ~/.config/nixos

# List archives
borg list borg@synology.local:/volume1/backups/orion

# If successful, delete test backup
borg delete borg@synology.local:/volume1/backups/orion::test-$(date +%Y%m%d)
```

### 3. Create Backup Module (Automated Setup - Day 7)

```nix
# modules/system/optional/services/backup.nix
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.services.backup;
in
{
  options.modules.services.backup = {
    enable = lib.mkEnableOption "Borg backup to Synology";
    
    synologyHost = lib.mkOption {
      type = lib.types.str;
      default = "synology.local";
      description = "Synology hostname or IP";
    };
    
    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Paths to backup";
    };
  };
  
  config = lib.mkIf cfg.enable {
    # Install Borg
    environment.systemPackages = [ pkgs.borgbackup ];
    
    # Borg backup service
    services.borgbackup.jobs.synology = {
      paths = cfg.paths;
      
      exclude = [
        "**/.cache"
        "**/.local/share/Trash"
        "**/node_modules"
        "**/target"
        "**/result"
        "**/.direnv"
      ];
      
      repo = "borg@${cfg.synologyHost}:/volume1/backups/${config.networking.hostName}";
      
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat /run/secrets/borg-passphrase";
      };
      
      compression = "auto,zstd";
      
      startAt = "daily";
      
      prune.keep = {
        daily = 7;
        weekly = 4;
        monthly = 6;
      };
      
      preHook = ''
        echo "Starting backup to Synology..."
      '';
      
      postHook = ''
        echo "Backup completed at $(date)"
      '';
    };
    
    # Add borg passphrase secret
    sops.secrets.borg-passphrase = {
      sopsFile = ../../secrets.yaml;  # or per-host secrets
    };
  };
}
```

### 4. Enable on Orion

```nix
# systems/orion/default.nix
modules.services.backup = {
  enable = true;
  synologyHost = "synology.local";  # or IP address
  paths = [
    "/home/syg/Documents"
    "/home/syg/Pictures"
    "/home/syg/.config"
    "/etc/nixos"
  ];
};
```

---

## Verification Checklist

After completing all days:

- [ ] Pre-flight script works and catches issues
- [ ] Validation script confirms successful deploys
- [ ] `just` commands are muscle memory
- [ ] Core/optional migration complete
- [ ] Can rebuild both systems successfully
- [ ] Manual Borg backup to Synology works
- [ ] (Optional) Automated Borg backup running

---

## Next Steps (Week 2+)

See `COMPARISON-ANALYSIS.md` for:
- Phase 2: YubiKey integration
- Phase 3: Homelab expansion (Proxmox, Frigate)
- Phase 4: Testing infrastructure, monitoring

---

## Troubleshooting

### Pre-flight Script Fails

**Problem:** "SSH connection failed"
- Check: `ssh -v jarvis@192.168.1.7` (verbose output)
- Verify: SSH key is added (`ssh-add -L`)
- Verify: User exists on Cortex (`just ssh-cortex "whoami"`)

**Problem:** "Not a NixOS system"
- Check: `just ssh-cortex "cat /etc/os-release"`
- Verify: You're deploying to correct IP

### Validation Script Fails

**Problem:** "Lost SSH access"
- **DO NOT PANIC** - System is still running
- Try: Wait 30 seconds, SSH may be restarting
- Try: Reboot from physical access
- Last resort: Boot from live USB, rollback to previous generation

**Problem:** "Critical services failed"
- Check: `just ssh-cortex "systemctl status sshd"`
- Check: `just ssh-cortex "systemctl status NetworkManager"`
- Fix: Restart service or rollback

### Just Commands Not Found

**Problem:** `command not found: just`
- Install: Add to `environment.systemPackages`
- Rebuild: `sudo nixos-rebuild switch`
- Verify: `which just`

### Borg Backup Fails

**Problem:** "Connection refused"
- Check: Synology SSH is enabled (Control Panel > Terminal & SNMP)
- Check: borg user exists on Synology
- Test: `ssh borg@synology.local` (should prompt for password)

**Problem:** "Repository not found"
- Check: Path exists: `ssh borg@synology.local "ls -la /volume1/backups/orion"`
- Reinitialize: `borg init --encryption=repokey-blake2 borg@synology.local:/volume1/backups/orion`

---

**End of Quick Wins Guide**

*These changes will immediately improve your deployment reliability and workflow consistency.*
