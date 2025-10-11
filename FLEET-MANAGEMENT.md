````markdown
# NixOS Fleet Management Guide

This guide explains how to deploy and manage multiple NixOS systems using the universal fleet management tools in this repository.

## Overview

This repository provides a scalable approach to managing multiple NixOS machines:

- **nixos-anywhere**: For initial system deployment (wipes disk, installs from scratch)
- **Colmena**: For routine updates to existing systems (parallel, tag-based deployment)
- **deploy-rs**: Alternative deployment tool (available but Colmena recommended)
- **fleet-deploy.sh**: Universal wrapper script that handles both deployment modes

## System Tags

Systems are organized with tags for selective deployment:

| Tag | Purpose | Systems |
|-----|---------|---------|
| `ai` | AI/ML systems | cortex |
| `server` | Server systems | cortex |
| `workstation` | Desktop/laptop systems | orion |
| `local` | Local machine | orion |
| `deployed` | Already deployed | cortex |

Use tags to update groups of systems:
```bash
./scripts/fleet-deploy.sh update --on @ai        # All AI systems
./scripts/fleet-deploy.sh update --on @server    # All servers
./scripts/fleet-deploy.sh update --on @local     # Local machine
```

## Architecture

```
┌────────────────────────────────────────────────────────────┐
│                    Your Workstation                        │
│                      (Orion)                               │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  NixOS Configuration Repository                      │  │
│  │  - flake.nix (defines all systems + Colmena)         │  │
│  │  - systems/cortex/default.nix                        │  │
│  │  - systems/orion/default.nix                         │  │
│  │  - scripts/fleet-deploy.sh (deployment tool)         │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────────────────────────────────────────┘
                         │
                         │ Colmena (parallel deploy/update)
                         ↓
┌───────────────────────────────────────────────────────────┐
│              Remote NixOS Systems (Fleet)                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐           │
│  │    Cortex  │  │  Server 2  │  │  Server 3  │   ...     │
│  │  AI Server │  │ @server    │  │ @backup    │           │
│  │ @ai @server│  │            │  │            │           │
│  └────────────┘  └────────────┘  └────────────┘           │
└───────────────────────────────────────────────────────────┘
```

## Quick Start

### List Available Systems

```bash
cd ~/.config/nixos
./scripts/fleet-deploy.sh list
# or: colmena introspect
```

### Check Configuration

```bash
# Validate flake configuration
./scripts/fleet-deploy.sh check
```

### Build Configuration Locally (Dry-Run)

```bash
# Build Cortex config locally to validate before deploying
./scripts/fleet-deploy.sh build cortex

# Build all systems
./scripts/fleet-deploy.sh build --all
```

### Initial Deployment (nixos-anywhere)

**⚠️ WARNING: This will completely wipe the target disk!**

Use this only for:
- Brand new systems
- Complete reinstallation
- Disaster recovery

```bash
# Deploy Cortex to 192.168.1.34 (wipes disk!)
./scripts/fleet-deploy.sh fresh cortex 192.168.1.34

# Deploy new system
./scripts/fleet-deploy.sh fresh newsystem 192.168.1.50
```

### Update Existing System (Colmena)

Use this for routine configuration updates:

```bash
# Update specific system
./scripts/fleet-deploy.sh update cortex

# Update all systems
./scripts/fleet-deploy.sh update --all

# Update by tag (AI systems)
./scripts/fleet-deploy.sh update --on @ai

# Update multiple specific systems
./scripts/fleet-deploy.sh update --on cortex,orion

# Direct Colmena usage
colmena apply --on cortex
colmena apply --on @server
colmena apply  # all systems
```

## Adding New Systems to Your Fleet

### Step 1: Create System Configuration

```bash
cd ~/.config/nixos/systems
mkdir my-server
```

Create `systems/my-server/default.nix`:

```nix
{ config, pkgs, lib, ... }:
{
  imports = [
    ./disk-config.nix  # Optional: use disko for disk setup
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  networking.hostName = "my-server";

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

  # Add your services, packages, etc.
  environment.systemPackages = with pkgs; [
    vim
    git
    htop
  ];

  system.stateVersion = "24.11";
}
```

### Step 2: Add to flake.nix

Add your system to `nixosConfigurations`:

```nix
nixosConfigurations = {
  # ... existing systems ...
  
  my-server = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit self system inputs fh userVars hasSecrets;
    };
    modules = withOptionalSecrets [
      disko.nixosModules.disko  # Optional
      ./systems/my-server
    ];
  };
};
```

Add to `colmenaHive` for fleet deployment (recommended):

```nix
colmenaHive = colmena.lib.makeHive {
  # ... meta and defaults ...
  
  my-server = { name, nodes, ... }: {
    imports = withOptionalSecrets [
      disko.nixosModules.disko
      ./systems/my-server
    ];
    deployment = {
      targetHost = "my-server";      # hostname or IP
      targetUser = "admin";           # SSH user
      tags = [ "server" "production" ];  # for selective deployment
    };
  };
};
```

Optionally also add to `deploy.nodes` if you want to use deploy-rs:

```nix
deploy.nodes = {
  # ... existing nodes ...
  
  my-server = {
    hostname = "my-server.local";  # or IP address
    profiles.system = {
      sshUser = "admin";
      user = "root";
      sudo = "sudo -u";
      path = deploy-rs.lib.${system}.activate.nixos self.nixosConfigurations.my-server;
    };
    autoRollback = true;
    magicRollback = true;
    remoteBuild = false;
  };
};
```

### Step 3: Deploy

```bash
# Build and test locally first
./scripts/fleet-deploy.sh build my-server

# Initial deployment (wipes disk!)
./scripts/fleet-deploy.sh fresh my-server 192.168.1.100

# Future updates (Colmena)
./scripts/fleet-deploy.sh update my-server

# Or update all production servers
./scripts/fleet-deploy.sh update --on @production
```

## Deployment Workflow

### Initial Setup (One-Time)

```bash
# 1. Prepare target machine (boot from USB or use nixos-genesis ISO)
# 2. Get target IP address
# 3. Deploy using nixos-anywhere
./scripts/fleet-deploy.sh fresh cortex 192.168.1.34
```

### Routine Updates (Daily/Weekly)

```bash
# 1. Make configuration changes in systems/cortex/
# 2. Build locally to validate
./scripts/fleet-deploy.sh build cortex

# 3. Deploy with Colmena
./scripts/fleet-deploy.sh update cortex

# Or update all AI systems
./scripts/fleet-deploy.sh update --on @ai

# Or update everything
./scripts/fleet-deploy.sh update --all
```

## Advanced Features

### Colmena Features

Colmena provides powerful fleet management capabilities:

- **Parallel Deployment**: Deploy to multiple hosts simultaneously
- **Tag-based Targeting**: Group systems by function and deploy selectively
- **Simple Configuration**: Integrated directly into flake.nix
- **Progress Tracking**: Real-time status for all deployments
- **Stateless Operation**: No central database or state to manage

#### Colmena Commands

```bash
# Deploy all systems in parallel
colmena apply

# Deploy specific system
colmena apply --on cortex

# Deploy by tag
colmena apply --on @ai
colmena apply --on @server

# Deploy multiple systems
colmena apply --on cortex,orion

# Build without deploying
colmena build

# Show system information
colmena introspect

# Execute command on all hosts
colmena exec -- uptime

# Execute on tagged hosts
colmena exec --on @server -- systemctl status
```

### Deploy-rs Options (Alternative)

Deploy-rs is also configured but Colmena is recommended for fleet management:

- **Automatic Rollback**: If activation fails, automatically reverts
- **Magic Rollback**: Requires confirmation after activation (prevents network config issues)
- **Health Checks**: Built-in checks ensure system is accessible after deployment
- **Profile-based Deployment**: Can deploy different profiles to different users

### Deploying to Multiple Systems

```bash
# Update all systems with Colmena (parallel)
./scripts/fleet-deploy.sh update --all

# Update by tag
./scripts/fleet-deploy.sh update --on @server

# Update multiple specific systems
./scripts/fleet-deploy.sh update --on cortex,server2,server3
```

## Tool Comparison

### Colmena vs nixos-anywhere

| Feature | Colmena | nixos-anywhere |
|---------|---------|----------------|
| **Purpose** | Update existing | Fresh install |
| **Target** | Live systems | New/clean systems |
| **Disk** | Preserves data | Wipes disk completely |
| **Speed** | Fast updates | Full installation |
| **Use case** | Daily updates | Initial deployment |
| **Parallel** | Yes | No |

### Colmena vs deploy-rs

| Feature | Colmena | deploy-rs |
|---------|---------|-----------|
| **Config** | Simpler | More complex |
| **Fleet focus** | Excellent | Good |
| **Tags** | Native support | Manual |
| **Parallel** | Built-in | Built-in |
| **Rollback** | Manual | Automatic |
| **Best for** | Multi-host fleets | Single/few hosts |

**Recommendation**: Use Colmena for fleet management, deploy-rs for critical single-host deployments requiring automatic rollback.

### Remote Builds

For systems with limited resources, you can build on the target:

In `flake.nix` (Colmena):

```nix
my-low-power-server = { name, nodes, ... }: {
  imports = [ ./systems/my-low-power-server ];
  deployment = {
    targetHost = "my-low-power-server";
    targetUser = "admin";
    buildOnTarget = true;  # Build on target instead of locally
    tags = [ "low-power" ];
  };
};
```

In `flake.nix` (deploy-rs):

```nix
deploy.nodes.my-low-power-server = {
  # ... other config ...
  remoteBuild = true;  # Build on target instead of locally
};
```

### Custom SSH Options

Override SSH settings per-deployment:

In `flake.nix`:

```nix
deploy.nodes.my-server = {
  # ... other config ...
  profiles.system = {
    sshUser = "admin";
    user = "root";
    sshOpts = [ "-p" "2222" "-i" "/path/to/key" ];
  };
};
```

## Troubleshooting

### Connection Issues

```bash
# Check SSH connectivity
./scripts/nixos-fleet.sh check cortex

# Manual SSH test
ssh jarvis@cortex
```

### Build Failures

```bash
# Build locally with detailed output
nix build .#nixosConfigurations.cortex.config.system.build.toplevel --show-trace

# Check for syntax errors
nix flake check
```

### Deployment Failures

Deploy-rs automatically rolls back failed deployments. Check:

```bash
# View system logs
ssh jarvis@cortex "journalctl -xe"

# Check service status
ssh jarvis@cortex "systemctl status"
```

### GitHub Rate Limiting

If you get rate limited when updating flake inputs:

```bash
# Wait and retry
sleep 300
nix flake lock --update-input deploy-rs

# Or use a GitHub token
export GITHUB_TOKEN="your_token"
nix flake lock --update-input deploy-rs
```

## Current Fleet

### Cortex (AI Server)

- **Purpose**: Artificial Intelligence Data Analyser
- **Hostname**: cortex
- **IP**: 192.168.1.34 (DHCP reservation recommended)
- **Admin User**: jarvis
- **Services**: fail2ban, auditd, SSH hardening
- **Marvel Theme**: Named after Cortex from Agents of S.H.I.E.L.D.

**Update Cortex**:

```bash
# Using fleet-deploy.sh wrapper
./scripts/fleet-deploy.sh update cortex

# Direct Colmena
colmena apply --on cortex

# Update all AI systems
./scripts/fleet-deploy.sh update --on @ai
```

### Orion (Desktop Workstation)

- **Purpose**: Primary development workstation
- **Hostname**: orion
- **Hardware**: Framework 13 with AMD 7040
- **User**: syg

**Local updates** (on Orion itself):

```bash
sudo nixos-rebuild switch --flake .#orion
```

## Best Practices

### 1. Always Build Locally First

```bash
# Catch errors before deploying
./scripts/nixos-fleet.sh build <system>
```

### 2. Test in Stages

- Build locally
- Deploy to test system
- Verify functionality
- Deploy to production

### 3. Use Version Control

```bash
# Commit before deploying
git add -A
git commit -m "feat: update cortex configuration"
git push

# Deploy
./scripts/nixos-fleet.sh update cortex
```

### 4. Monitor Deployments

Watch the deployment output for:
- Build errors
- Connection issues
- Service failures
- Rollback triggers

### 5. Keep Backups

Deploy-rs automatically keeps previous generations:

```bash
# View available generations
ssh jarvis@cortex "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system"

# Rollback to previous generation
ssh jarvis@cortex "sudo nixos-rebuild switch --rollback"
```

## Security Considerations

### SSH Keys

Ensure SSH keys are properly configured:

```nix
users.users.admin.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-key"
];
```

### Secrets Management

Use sops-nix for sensitive data:

```nix
sops.secrets."myservice/password" = {
  sopsFile = ../secrets/secrets.yaml;
};
```

### Firewall

Always configure a firewall:

```nix
networking.firewall = {
  enable = true;
  allowedTCPPorts = [ 22 ];  # SSH only
};
```

## Next Steps

1. **Configure DHCP Reservations**: Assign static IPs via your router
2. **Set Up Monitoring**: Add health check monitoring for all systems
3. **Automate Updates**: Create cron jobs or systemd timers for updates
4. **Document Your Fleet**: Keep this guide updated as you add systems
5. **Set Up Secrets**: Use sops-nix for password and key management

## See Also

- [Cortex-COMPLETE.md](../Cortex-COMPLETE.md) - Complete Cortex documentation
- [Cortex-SECURITY.md](../Cortex-SECURITY.md) - Security implementation details
- [deploy-rs Documentation](https://github.com/serokell/deploy-rs)
- [nixos-anywhere Documentation](https://github.com/nix-community/nixos-anywhere)
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)

---

**Last Updated**: October 6, 2025
