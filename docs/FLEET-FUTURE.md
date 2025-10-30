# Future Fleet Management with Colmena

**Reference guide for future Colmena integration and advanced fleet patterns.**

**Status:** 📋 Planning / Reference Only  
**Target:** Month 3-4 (When Colmena supports newer flake syntax)

---

## Why Colmena?

**Current limitations with deploy-rs:**
- Sequential deployments (one at a time)
- Manual targeting (must specify each host)
- No built-in tagging system
- More complex configuration

**Colmena advantages:**
- ✅ Parallel deployment to multiple hosts
- ✅ Tag-based targeting (@server, @ai, @workstation)
- ✅ Simpler fleet configuration
- ✅ Built-in health checks and status tracking
- ✅ Easy command execution across fleet

**When to migrate:**
- Managing 5+ systems
- Need parallel deployments (time savings)
- Want tag-based organization
- Colmena supports current flake syntax

---

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

**Recommendation:** Use both - nixos-anywhere for bootstrap, Colmena for updates

### Colmena vs deploy-rs

| Feature | Colmena | deploy-rs |
|---------|---------|-----------|
| **Config** | Simpler | More complex |
| **Fleet focus** | Excellent | Good |
| **Tags** | Native support | Manual |
| **Parallel** | Built-in | Built-in |
| **Rollback** | Manual | Automatic |
| **Best for** | Multi-host fleets | Single/few hosts |

---

## Colmena Configuration

### flake.nix Structure

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    colmena.url = "github:zhaofengli/colmena";
  };

  outputs = { self, nixpkgs, colmena, ... }: {
    # Standard nixosConfigurations (keep these)
    nixosConfigurations = {
      cortex = nixpkgs.lib.nixosSystem { /* ... */ };
      orion = nixpkgs.lib.nixosSystem { /* ... */ };
    };

    # Colmena configuration
    colmena = {
      meta = {
        nixpkgs = import nixpkgs { system = "x86_64-linux"; };
        nodeNixpkgs = builtins.mapAttrs (_: v: v.pkgs) self.nixosConfigurations;
      };

      defaults = { config, ... }: {
        # Common configuration for all hosts
        deployment = {
          targetUser = "root";
          buildOnTarget = false;  # Build locally
        };
      };

      # Individual hosts
      cortex = { name, nodes, ... }: {
        imports = [ ./systems/cortex ];
        deployment = {
          targetHost = "cortex.local";  # or "192.168.1.7"
          targetUser = "jarvis";
          tags = [ "server" "ai" "deployed" ];
        };
      };

      orion = { name, nodes, ... }: {
        imports = [ ./systems/orion ];
        deployment = {
          targetHost = "orion.local";
          targetUser = "syg";
          tags = [ "workstation" "local" ];
        };
      };

      proxmox = { name, nodes, ... }: {
        imports = [ ./systems/proxmox ];
        deployment = {
          targetHost = "proxmox.local";
          targetUser = "admin";
          tags = [ "server" "homelab" ];
          buildOnTarget = true;  # Build on low-power systems
        };
      };
    };
  };
}
```

### Tag Organization

```nix
tags = [
  # By function
  "ai"           # AI/ML systems
  "server"       # Server systems
  "workstation"  # Desktop/laptop systems
  "homelab"      # Homelab infrastructure
  
  # By deployment state
  "deployed"     # Already deployed
  "testing"      # Test systems
  "production"   # Production systems
  
  # By location
  "local"        # Local machine
  "remote"       # Remote systems
  "datacenter"   # Hosted systems
];
```

---

## Colmena Commands

### Basic Operations

```bash
# List all systems and their tags
colmena introspect

# Deploy to all systems (parallel)
colmena apply

# Deploy to specific system
colmena apply --on cortex

# Deploy by tag
colmena apply --on @ai           # All AI systems
colmena apply --on @server       # All servers
colmena apply --on @workstation  # All workstations

# Deploy to multiple systems
colmena apply --on cortex,orion,proxmox

# Deploy to multiple tags
colmena apply --on @server,@ai
```

### Build Operations

```bash
# Build without deploying
colmena build

# Build specific system
colmena build --on cortex

# Build by tag
colmena build --on @server
```

### Remote Execution

```bash
# Execute command on all hosts
colmena exec -- uptime

# Execute on tagged hosts
colmena exec --on @server -- systemctl status nginx

# Execute on specific hosts
colmena exec --on cortex,orion -- df -h
```

### Health Checks

```bash
# Check reachability of all hosts
colmena exec -- echo "I'm alive!"

# Get status of all systems
colmena exec -- nixos-version

# Check service across fleet
colmena exec --on @server -- systemctl status sshd
```

---

## Migration Path

### Phase 1: Add Colmena to Flake (1 hour)

```bash
# 1. Add Colmena input to flake.nix
nix flake lock --update-input colmena

# 2. Add colmena output to flake.nix
# (see configuration example above)

# 3. Install colmena
nix profile install nixpkgs#colmena
# or add to system packages

# 4. Verify configuration
colmena introspect
```

### Phase 2: Parallel Deployment Testing (1 hour)

```bash
# 1. Test on non-critical systems first
colmena build --on @testing

# 2. Deploy to test systems
colmena apply --on @testing

# 3. Verify success
colmena exec --on @testing -- systemctl is-system-running
```

### Phase 3: Update Just Commands (30 minutes)

Update `justfile`:

```justfile
# Deploy all systems (parallel)
deploy-all:
  colmena apply

# Deploy by tag
deploy-servers:
  colmena apply --on @server

deploy-ai:
  colmena apply --on @ai

# Deploy specific systems
deploy-cortex:
  colmena apply --on cortex

# Fleet-wide operations
fleet-status:
  colmena exec -- systemctl is-system-running

fleet-uptime:
  colmena exec -- uptime

fleet-versions:
  colmena exec -- nixos-version
```

### Phase 4: Update Scripts (1 hour)

Update `fleet.sh` to use Colmena when available:

```bash
# Check if colmena is available
if command -v colmena &> /dev/null; then
  use_colmena=true
else
  use_colmena=false
fi

# Update function
if [ "$use_colmena" = true ]; then
  colmena apply --on "$system"
else
  deploy .#"$system"
fi
```

---

## Advanced Patterns

### Conditional Deployment

```nix
# Deploy different configs based on tags
cortex = { name, nodes, ... }: {
  imports = [ ./systems/cortex ];
  
  # Enable monitoring only on production systems
  services.prometheus.enable = 
    builtins.elem "production" nodes.${name}.deployment.tags;
    
  deployment = {
    targetHost = "cortex.local";
    tags = [ "server" "ai" "production" ];
  };
};
```

### Secrets Per-Host

```nix
# Use different secrets based on system
cortex = { name, nodes, ... }: {
  imports = [ 
    ./systems/cortex 
    (nixos-secrets + "/hosts/cortex.nix")  # Host-specific secrets
  ];
};
```

### Remote Builds

```nix
# Build on systems with limited resources
raspberrypi = { name, nodes, ... }: {
  imports = [ ./systems/raspberrypi ];
  deployment = {
    targetHost = "raspberrypi.local";
    buildOnTarget = true;  # Build on target instead of locally
    tags = [ "iot" "low-power" ];
  };
};
```

---

## Fleet Scaling Example

### Target Architecture (5+ Systems)

```
Your Fleet (Month 3+)
├── Workstations
│   ├── orion      (@workstation, @local)
│   └── laptop2    (@workstation, @remote)
├── Servers
│   ├── cortex     (@server, @ai, @production)
│   └── proxmox    (@server, @homelab, @production)
├── Homelab VMs (on Proxmox)
│   ├── frigate    (@homelab, @nvr, @production)
│   ├── jellyfin   (@homelab, @media, @production)
│   └── home-assistant (@homelab, @automation, @production)
└── IoT Devices
    ├── pi-1       (@iot, @monitoring)
    └── pi-2       (@iot, @sensors)
```

### Tag-Based Deployment

```bash
# Update all production systems
colmena apply --on @production

# Update homelab infrastructure
colmena apply --on @homelab

# Update AI systems only
colmena apply --on @ai

# Emergency update to all servers
colmena apply --on @server

# Update everything except local machine
colmena apply --on @deployed
```

---

## Monitoring and Observability

### Fleet-Wide Status

```bash
# Check system status
colmena exec -- systemctl is-system-running

# Check uptime
colmena exec -- uptime

# Check disk usage
colmena exec -- df -h /

# Check memory
colmena exec -- free -h

# Check NixOS versions
colmena exec -- nixos-version

# Check failed services
colmena exec -- systemctl --failed
```

### Automated Health Checks

Create `scripts/fleet-health.sh`:

```bash
#!/usr/bin/env bash
# Fleet health check

echo "=== Fleet Health Report ==="
echo ""

echo "System Status:"
colmena exec -- systemctl is-system-running

echo ""
echo "Uptime:"
colmena exec -- uptime

echo ""
echo "Disk Usage (root):"
colmena exec -- df -h / | grep -E "Filesystem|/$"

echo ""
echo "Failed Services:"
colmena exec -- systemctl --failed --no-legend | wc -l
```

Run daily:

```bash
# Add to cron or systemd timer
just fleet-health
```

---

## Cost/Benefit Analysis

### Time Savings

**Without Colmena (Sequential):**
- 2 systems: 10 minutes (5 min each)
- 5 systems: 25 minutes (5 min each)
- 10 systems: 50 minutes (5 min each)

**With Colmena (Parallel):**
- 2 systems: 5 minutes (parallel)
- 5 systems: 5 minutes (parallel)
- 10 systems: 5-7 minutes (parallel)

**Break-even point:** 3+ systems

### Complexity Trade-off

**Added Complexity:**
- New flake output (colmena configuration)
- Tag management
- Parallel deployment coordination

**Reduced Complexity:**
- Single command for fleet updates
- No need to track which systems to update
- Simpler fleet-wide operations

**Worth it when:** Managing 5+ systems regularly

---

## Resources

### Colmena Documentation
- [GitHub](https://github.com/zhaofengli/colmena)
- [Manual](https://colmena.cli.rs/)
- [Tutorial](https://colmena.cli.rs/unstable/tutorial.html)

### Community Examples
- [EmergentMind's nix-config](https://github.com/EmergentMind/nix-config) (uses Colmena)
- [NixOS Discourse - Colmena](https://discourse.nixos.org/search?q=colmena)

### Alternative Tools
- [deploy-rs](https://github.com/serokell/deploy-rs) - What you're using now
- [nixus](https://github.com/Infinidoge/nixus) - Another fleet tool
- [morph](https://github.com/DBCDK/morph) - Older fleet tool

---

**Last Updated:** October 29, 2025  
**Status:** Reference / Planning  
**Target Date:** Month 3-4 (Q1 2026)
