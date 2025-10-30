# NixOS Fleet Management

**Practical guide to deploying and managing multiple NixOS systems using your current toolset.**

**Current Stack:** `just` + `deploy-rs` + `fleet.sh` + `safe-deploy.sh`

**Last Updated:** October 29, 2025

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Your Fleet](#your-fleet)
3. [Common Tasks](#common-tasks)
4. [Fleet Script](#fleet-script)
5. [Adding New Systems](#adding-new-systems)
6. [Troubleshooting](#troubleshooting)

---

## Quick Start

### List Available Systems

```bash
./scripts/fleet.sh list
```

### Deploy to a System

```bash
# Recommended: Use just commands (includes safety checks)
just deploy-cortex

# Alternative: Direct script
./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis

# Alternative: Using fleet script
./scripts/fleet.sh update cortex
```

### Local Rebuild

```bash
# On Orion (laptop)
just rebuild-orion

# With debugging
just rebuild-trace orion
```

---

## Your Fleet

### Current Systems

| System | Type | Hardware | IP | User | Status |
|--------|------|----------|----|----- |--------|
| **Orion** | Workstation | Framework 13 (AMD 7040) | 192.168.1.x | syg | ✅ Active |
| **Cortex** | AI Server | RTX 5090 (32GB VRAM) | 192.168.1.7 | jarvis | ✅ Active |

### Architecture

```
┌────────────────────────────────┐
│    Orion (Your Workstation)    │
│  ┌──────────────────────────┐  │
│  │  NixOS Config Repo       │  │
│  │  - flake.nix             │  │
│  │  - systems/              │  │
│  │  - scripts/              │  │
│  │  - justfile              │  │
│  └──────────────────────────┘  │
└────────────────────────────────┘
          │
          │ deploy-rs
          ↓
┌────────────────────────────────┐
│       Cortex (AI Server)       │
│    192.168.1.7 (jarvis)        │
│  - Ollama + LLM models         │
│  - RTX 5090 + CUDA             │
│  - Security hardening          │
└────────────────────────────────┘
```

---

## Common Tasks

All commands assume you're in `/home/syg/.config/nixos`.

### Using Just (Recommended)

```bash
# Show all available commands
just --list

# === Local Operations (Orion) ===
just rebuild-orion              # Rebuild Orion locally
just update-orion               # Update flake inputs + rebuild

# === Remote Operations (Cortex) ===
just deploy-cortex              # Deploy to Cortex (with safety checks)
just check-cortex               # Pre-flight checks only
just validate-cortex            # Post-deploy validation
just ssh-cortex                 # SSH into Cortex

# === Updates ===
just update                     # Update all flake inputs
just update-input nixpkgs       # Update specific input

# === Secrets Management ===
just update-secrets             # Sync nixos-secrets repo
just edit-secrets               # Edit encrypted secrets
just rekey                      # Rekey secrets after host changes
```

### Direct Script Usage

```bash
# Fleet management script
./scripts/fleet.sh list                    # List all systems
./scripts/fleet.sh build cortex            # Build config locally
./scripts/fleet.sh check cortex            # Check system health
./scripts/fleet.sh update cortex           # Deploy updates

# Safe deployment (with pre-flight checks)
./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis

# Individual check scripts
./scripts/pre-flight.sh cortex 192.168.1.7 jarvis    # Before deploy
./scripts/validate.sh cortex 192.168.1.7 jarvis      # After deploy
```

### Using deploy-rs Directly

```bash
# Deploy to Cortex
deploy --skip-checks .#cortex -- --impure

# With automatic rollback on failure
deploy .#cortex

# Check configuration validity
nix flake check
```

---

## Fleet Script

The `fleet.sh` script auto-discovers systems from your flake and provides unified management.

### Auto-Discovery

```bash
# List all systems defined in flake.nix
./scripts/fleet.sh list
```

Output:
```
Available systems:
  - orion
  - cortex
  - nexus
```

### Build Configurations Locally

```bash
# Build Cortex config to validate before deploying
./scripts/fleet.sh build cortex

# Build all systems
for system in $(./scripts/fleet.sh list); do
  ./scripts/fleet.sh build $system
done
```

### Health Checks

```bash
# Check Cortex connectivity and health
./scripts/fleet.sh check cortex
```

The check performs:
1. ✅ SSH key verification
2. ✅ Network connectivity test
3. ✅ SSH authentication test
4. ✅ System health check (uptime, load, disk)
5. ✅ Service status verification

### Deployment

```bash
# Deploy to Cortex (uses deploy-rs)
./scripts/fleet.sh update cortex
```

---

## Adding New Systems

### Step 1: Create System Configuration

```bash
mkdir -p systems/newsystem
```

Create `systems/newsystem/default.nix`:

```nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./hardware.nix
    ./disk-config.nix  # Optional: disko
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "newsystem";

  users.users.admin = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" ];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAA... your-key"
    ];
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  system.stateVersion = "24.11";
}
```

Create `systems/newsystem/variables.nix`:

```nix
{
  system = {
    hostname = "newsystem";
  };

  user = {
    username = "admin";
  };

  network = {
    hostname = "newsystem";
    ip = "192.168.1.50";
    ssh = {
      user = "admin";
      port = 22;
    };
  };
}
```

### Step 2: Add to flake.nix

Add to `nixosConfigurations`:

```nix
nixosConfigurations = {
  # ... existing systems ...
  
  newsystem = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit self system inputs fh userVars hasSecrets;
    };
    modules = withOptionalSecrets [
      disko.nixosModules.disko  # Optional
      ./systems/newsystem
    ];
  };
};
```

Add to `deploy.nodes` for deploy-rs:

```nix
deploy.nodes = {
  # ... existing nodes ...
  
  newsystem = {
    hostname = "newsystem.local";  # or IP: "192.168.1.50"
    profiles.system = {
      sshUser = "admin";
      user = "root";
      sudo = "sudo -u";
      path = deploy-rs.lib.${system}.activate.nixos 
             self.nixosConfigurations.newsystem;
    };
    autoRollback = true;
    magicRollback = true;
  };
};
```

### Step 3: Add Just Commands (Optional)

Add to `justfile`:

```justfile
# Deploy to newsystem
deploy-newsystem: rebuild-pre
  ./scripts/safe-deploy.sh newsystem 192.168.1.50 admin

# Check newsystem
check-newsystem:
  ./scripts/pre-flight.sh newsystem 192.168.1.50 admin

# SSH to newsystem
ssh-newsystem:
  ssh admin@192.168.1.50
```

### Step 4: Bootstrap or Deploy

**For new/clean system (wipes disk!):**

```bash
# Bootstrap with nixos-anywhere
./scripts/bootstrap-nixos.sh -n newsystem -d 192.168.1.50 -u admin
```

**For existing system:**

```bash
# Build locally first
./scripts/fleet.sh build newsystem

# Deploy
just deploy-newsystem
# or
./scripts/fleet.sh update newsystem
```

---

## Troubleshooting

### Connection Issues

**Problem:** Can't connect to remote system

**Solutions:**

1. **Check network connectivity:**
   ```bash
   ping 192.168.1.7
   ```

2. **Test SSH manually:**
   ```bash
   ssh jarvis@192.168.1.7 "echo 'SSH OK'"
   ```

3. **Verify SSH keys loaded:**
   ```bash
   ssh-add -l
   ```

4. **Check target system SSH service:**
   ```bash
   ssh jarvis@192.168.1.7 "systemctl status sshd"
   ```

### Build Failures

**Problem:** Configuration fails to build

**Solutions:**

1. **Build locally with trace:**
   ```bash
   nix build .#nixosConfigurations.cortex.config.system.build.toplevel --show-trace
   ```

2. **Check for syntax errors:**
   ```bash
   nix flake check
   ```

3. **Validate specific file:**
   ```bash
   nix-instantiate --parse systems/cortex/default.nix
   ```

### Deployment Failures

**Problem:** deploy-rs fails or times out

**Solutions:**

1. **Check pre-flight:**
   ```bash
   just check-cortex
   ```

2. **View target system logs:**
   ```bash
   ssh jarvis@192.168.1.7 "journalctl -xe"
   ```

3. **Check for stuck activations:**
   ```bash
   ssh jarvis@192.168.1.7 "systemctl list-jobs"
   ```

4. **Manual rollback if needed:**
   ```bash
   ssh jarvis@192.168.1.7 "sudo nixos-rebuild switch --rollback"
   ```

### Secrets Issues

**Problem:** Secrets not decrypting on target

**Solutions:**

1. **Verify age key exists:**
   ```bash
   ssh jarvis@192.168.1.7 "ls -l /etc/ssh/ssh_host_ed25519_key"
   ```

2. **Check sops-nix service:**
   ```bash
   ssh jarvis@192.168.1.7 "systemctl status sops-nix"
   ```

3. **Rekey secrets:**
   ```bash
   just rekey
   ```

4. **Verify in secrets repo:**
   ```bash
   cd ../nixos-secrets
   sops --decrypt secrets.yaml
   ```

### GitHub Rate Limiting

**Problem:** Rate limited when updating flake inputs

**Solutions:**

1. **Wait and retry:**
   ```bash
   sleep 300
   nix flake lock --update-input home-manager
   ```

2. **Use GitHub token:**
   ```bash
   export GITHUB_TOKEN="your_token"
   nix flake update
   ```

---

## Deployment Workflow

### Initial Setup (One-Time)

```bash
# 1. Prepare target machine
#    - Boot from NixOS LiveISO
#    - Get target IP address

# 2. Bootstrap system
./scripts/bootstrap-nixos.sh -n cortex -d 192.168.1.7 -u jarvis

# 3. Verify deployment
just check-cortex
just validate-cortex
```

### Routine Updates (Weekly)

```bash
# 1. Make configuration changes
vim systems/cortex/default.nix

# 2. Build locally to validate
./scripts/fleet.sh build cortex

# 3. Run pre-flight checks
just check-cortex

# 4. Deploy with safety checks
just deploy-cortex

# 5. Validate deployment
just validate-cortex
```

### Emergency Rollback

```bash
# View available generations
ssh jarvis@192.168.1.7 "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system"

# Rollback to previous generation
ssh jarvis@192.168.1.7 "sudo nixos-rebuild switch --rollback"

# Or rollback to specific generation
ssh jarvis@192.168.1.7 "sudo nix-env --switch-generation 42 --profile /nix/var/nix/profiles/system"
ssh jarvis@192.168.1.7 "sudo /nix/var/nix/profiles/system/bin/switch-to-configuration switch"
```

---

## Best Practices

### 1. Always Run Pre-flight Checks

```bash
# Built into just commands
just deploy-cortex  # Automatically runs pre-flight

# Or manually
just check-cortex
```

### 2. Build Locally First

```bash
# Catch errors before deploying
./scripts/fleet.sh build cortex
```

### 3. Use Version Control

```bash
# Commit before deploying
git add -A
git commit -m "feat: update cortex GPU drivers"
git push

# Deploy
just deploy-cortex
```

### 4. Test in Stages

- Build locally → Deploy to test system → Verify → Deploy to production

### 5. Monitor Deployments

Watch the output for:
- ✅ Build success
- ✅ Connection established
- ✅ Activation successful
- ⚠️ Service failures
- ⚠️ Rollback triggers

---

## Future Enhancements

See [docs/ROADMAP.md](docs/ROADMAP.md) for planned improvements:

- **Colmena Integration** (Month 3-4)
  - Parallel deployment to multiple systems
  - Tag-based targeting (@server, @ai, etc.)
  - Simpler fleet configuration

- **Expanded Just Automation** (Ongoing)
  - More pre-defined tasks
  - Better error handling
  - Integration with monitoring

- **Fleet Scaling** (Month 3+)
  - Proxmox VMs
  - Homelab services
  - 5+ systems in fleet

---

## Resources

### Documentation
- [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) - Bootstrap new systems
- [SECRETS.md](SECRETS.md) - Secrets management guide
- [docs/PROJECT-OVERVIEW.md](docs/PROJECT-OVERVIEW.md) - Overall architecture
- [docs/ROADMAP.md](docs/ROADMAP.md) - Future plans

### Tools
- [deploy-rs](https://github.com/serokell/deploy-rs) - NixOS deployment tool
- [just](https://github.com/casey/just) - Command runner
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) - Remote installation

### Community
- [EmergentMind's nix-config](https://github.com/EmergentMind/nix-config) - Production patterns
- [NixOS Discourse](https://discourse.nixos.org/) - Community forum
- [r/NixOS](https://reddit.com/r/NixOS) - Reddit community

---

**Last Updated:** October 29, 2025  
**Fleet Size:** 2 systems (Orion, Cortex)  
**Deployment Tool:** deploy-rs + just + fleet.sh
