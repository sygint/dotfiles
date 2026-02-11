# Security Roadmap

## Future Security Enhancements for Homelab 🛡️

**Status:** Conceptual / Not Yet Implemented  
**Purpose:** Document potential security improvements and architectures to consider for future homelab expansion

> **Note:** This document describes *potential* security architectures, not the current implementation. See `systems/cortex/default.nix` and other system configs for actual current security measures.

## User Isolation Strategy Concepts

### Current Setup (As Implemented)
```
Cortex (AI Server):
└── jarvis: 👤 Admin user
    ├── SSH: ✅ Key-only auth
    ├── Sudo: ✅ Full access
    └── Service Users:
        └── friday: 🤖 AI services (isolated)

Orion (Workstation):
└── syg: 👤 Primary user
    ├── Desktop environment
    └── Development tools
```

### Potential Enhanced Architecture (Future Consideration)
```
Concept: Functional Role-Based Access
└── Admin tier:
    ├── admin: 👤 System administration
    └── Service tier:
        ├── ai-svc: 🤖 AI services (Ollama, etc.)
        ├── monitor-svc: 🛡️ Security monitoring (fail2ban, intrusion detection)
        └── metrics-svc: � Analytics services (Prometheus, Grafana)
```

### Potential Security Improvements to Consider

| Feature | Current State | Potential Enhancement | Benefit |
|---------|---------------|----------------------|---------|
| **User Naming** | Descriptive (jarvis, friday) | Role-based (admin, ai-svc) | ✅ Clearer purpose |
| **Service Isolation** | Some isolation (friday user) | Full isolation per service | ✅ Better containment |
| **Network Segmentation** | Ubiquiti firewall rules | VLANs + microsegmentation | ✅ Layer 2 isolation |
| **Audit Granularity** | System-level auditd | Per-user audit trails | ✅ Enhanced forensics |
| **Secret Management** | sops-nix (current) | Vault or similar | ✅ Dynamic secrets |
| **Zero Trust** | Firewall + SSH keys | mTLS + per-service auth | ✅ Defense in depth |

## Network Architecture Considerations

### Current Homelab Setup
```
Internet → Ubiquiti UDM/USW
├── Orion (Workstation) - 192.168.1.100
├── Cortex (AI Server) - 192.168.1.7
├── Nexus (Homelab Services) - 192.168.1.10
└── Synology DS920+ - 192.168.1.50
```

### Potential VLAN Segmentation (Future)
```
Management VLAN (10):
├── Ubiquiti devices
└── Admin workstations

Server VLAN (20):
├── Cortex (AI)
└── Nexus (Services)

IoT/Camera VLAN (30):
├── Security cameras (when added)
└── Smart home devices

Storage VLAN (40):
└── Synology NAS
```

## Potential Operational Improvements

### Service User Isolation Pattern
```nix
# Example pattern for isolated service users
users.users.servicename = {
  isSystemUser = true;
  group = "servicename";
  home = "/var/lib/servicename";
  createHome = true;
};

# Limited sudo rules
security.sudo.extraRules = [{
  users = [ "servicename" ];
  commands = [{
    command = "/run/current-system/sw/bin/systemctl restart servicename-*";
    options = [ "NOPASSWD" ];
  }];
}];
```

### Ubiquiti Integration Ideas

**Firewall Rules (UDM/USG):**
- Geo-blocking for SSH (allow only home country)
- Rate limiting on management ports
- IDS/IPS for anomaly detection

**Network Policies:**
- IoT device isolation (cameras can't reach internet)
- Inter-VLAN rules (storage only accessible from server VLAN)
- Guest network completely isolated

## Security Principles Worth Considering

### Currently Implemented ✅
1. **SSH Key-Only Authentication** - No passwords accepted
2. **Root Login Disabled** - Must sudo from user account
3. **Fail2ban** - Automatic IP blocking for brute force attempts
4. **Audit Logging** - Track security-relevant events
5. **Firewall** - Restrictive rules, LAN-only access
6. **Service Isolation** - Separate user for AI services (friday)

### Potential Future Enhancements ⏳
1. **Network Segmentation** - VLANs for different security zones
2. **mTLS** - Mutual TLS for service-to-service communication
3. **Hardware Security Keys** - YubiKey/Nitrokey for admin access
4. **Intrusion Detection** - Suricata/Snort on Ubiquiti
5. **Automated Backups** - Encrypted, tested backup strategy (see Infrastructure section below)
6. **Secret Rotation** - Automatic credential rotation
7. **Monitoring Dashboard** - Centralized security monitoring (Grafana/Prometheus)

## Infrastructure & Automation Roadmap

### Backup Strategy (High Priority)

**Goal:** Automated encrypted backups to Synology DS-920+

**Borg Backup Implementation:**
```nix
# Potential configuration pattern
services.borgbackup.jobs.synology = {
  paths = [
    "/home"
    "/var/lib"
    "/etc/nixos"
  ];
  repo = "borg@synology.local:/volume1/backups/nixos";
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
};
```

**Benefits:**
- Deduplication (saves space)
- Encryption at rest
- Incremental backups (fast)
- Retention policy (automatic cleanup)
- Works with existing Synology

**Systems to Back Up:**
1. **Orion** - Development work, dotfiles, home directory
2. **Cortex** - AI models, datasets, configurations
3. **Nexus** - Homelab services data

### Task Automation with Fleet CLI

**Goal:** Standardize common workflows with a unified CLI

**Why Fleet CLI?**
- Single binary for all fleet operations
- Wraps Colmena for parallel deployments
- Built-in secrets management
- Self-documenting (`fleet --help`)

**Common Commands:**
```bash
# See all available commands
fleet --help

# Local rebuild
sudo nixos-rebuild switch --flake .

# Deploy to remote system
fleet push cortex

# Deploy to all servers
fleet push --tag server

# Check system health
fleet check cortex

# Manage secrets
fleet secrets edit
fleet secrets sync

# Fleet-wide operations
fleet status
fleet exec all -- uptime
```

**Integration with Existing Tools:**
- Wraps Colmena for deployment
- Integrates with SOPS for secrets
- Provides SSH shortcuts (`fleet ssh cortex`)

### Code Quality Automation

**Pre-commit Hooks:**
```nix
# Potential addition to devenv.nix or flake.nix
pre-commit.hooks = {
  nixfmt.enable = true;      # Format Nix files
  statix.enable = true;       # Lint Nix code
  deadnix.enable = true;      # Find unused code
  check-merge-conflict = true;
};
```

**Benefits:**
- Consistent code formatting
- Catch errors before commits
- Maintain code quality
- Prevent broken configs in git

### Home Manager Profiles Pattern (Future Scaling)

**Goal:** Reduce duplication across multiple systems with reusable profiles

**When to Implement:** When adding 4+ systems (Proxmox VMs, additional workstations)

**Pattern:**
```
modules/home/
├── profiles/           # Bundles of related modules
│   ├── desktop.nix    # Full desktop environment
│   ├── minimal.nix    # Shell-only (servers/VMs)
│   └── development.nix # Development tools
└── programs/          # Individual programs (current)
```

**Example Implementation:**
```nix
# modules/home/profiles/desktop.nix
{ ... }: {
  modules.programs = {
    # Window manager
    hyprland.enable = true;
    hyprpanel.enable = true;
    hypridle.enable = true;
    
    # Browsers
    brave.enable = true;
    librewolf.enable = true;
    
    # Development
    vscode.enable = true;
    zsh.enable = true;
    screenshots.enable = true;
  };
}

# modules/home/profiles/minimal.nix
{ ... }: {
  modules.programs = {
    zsh.enable = true;  # Just shell essentials
  };
}

# Usage in system configs:
# systems/orion/homes/syg.nix
imports = [ ../../../../modules/home/profiles/desktop.nix ];

# systems/proxmox-vm/homes/admin.nix
imports = [ ../../../../modules/home/profiles/minimal.nix ];
```

**Benefits:**
- Single source of truth for "desktop" configuration
- Easy to maintain consistency across workstations
- Quick setup for new systems
- Clear separation between profiles (desktop vs server)

**Reference:** Pattern inspired by Misterio77 and m3tam3re's configs

### Monitoring & Alerting (Future)

**Potential Stack:**
- **Prometheus** - Metrics collection
- **Grafana** - Visualization
- **Loki** - Log aggregation
- **Alertmanager** - Notifications

**What to Monitor:**
- System resources (CPU, RAM, disk)
- Service health (fail2ban, sshd, etc.)
- Backup success/failure
- Disk space warnings
- Temperature (GPU on Cortex)

## Implementation Considerations

### What Works Well for Homelab
- NixOS declarative configuration (reproducible security)
- SSH key authentication (simple, effective)
- Ubiquiti ecosystem (integrated firewall/IDS/IPS)
- Tailscale (secure remote access without port forwarding)

### What Might Be Overkill
- Enterprise IAM systems (Keycloak, etc.)
- Full zero-trust architecture
- Extensive compliance frameworks
- 24/7 SOC monitoring

### Sweet Spot for Homelab Security
1. Strong firewall rules (Ubiquiti)
2. SSH keys + Fail2ban
3. Basic VLANs (trusted/IoT/guest)
4. Automated updates (NixOS)
5. Regular backups (encrypted)
6. Monitoring alerts (critical services only)

---

**Remember:** Security is about risk management. Perfect security doesn't exist, but you can be secure enough for your threat model. For a homelab, focus on the high-impact, low-effort wins! 🎯
