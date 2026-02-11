# NixOS Configuration - Project Overview

Personal infrastructure as code -- a declarative, reproducible NixOS configuration for a privacy-focused home network.

---

## Project Purpose

This configuration manages a four-system NixOS fleet with emphasis on:

- **Security and Privacy**: No cloud dependencies, full disk encryption, VPN networking, hardened configs
- **Reproducibility**: Declarative infrastructure, version-controlled, consistently deployable
- **AI/ML Workloads**: GPU-accelerated LLM inference and development tooling (Cortex)
- **Development**: Multi-language support (JavaScript, Go, Rust, Zig)
- **Entertainment**: Media streaming (Jellyfin on Nexus), game streaming (Moonlight/Sunshine planned)
- **Fleet Management**: Centralized configuration with the `fleet` CLI

### Philosophy

1. **Stability over bleeding-edge** -- remote deployments must work reliably
2. **Modularity** -- one feature, one file, composable across systems
3. **Security by default** -- hardened configurations, minimal attack surface
4. **Privacy-first** -- self-hosted infrastructure, no cloud services
5. **Documentation** -- clear reference for maintenance and AI assistants

---

## Infrastructure

### Systems

| System | Type | Hardware | IP | User | Status |
|--------|------|----------|----|------|--------|
| **Orion** | Workstation | Framework 13 (AMD 7040) | local | syg | Active |
| **Cortex** | AI Server | RTX 5090 (32GB VRAM) | 192.168.1.7 | jarvis | Active |
| **Nexus** | Homelab Server | HP EliteDesk 800 G4 | -- | admin | Active |
| **Axon** | HTPC | Streaming client | -- | -- | Active |

### Network

```
┌────────────────────────────────────────────────────────┐
│                 Home Network (UDM Pro)                  │
│               (192.168.1.0/24)                         │
│                                                        │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐  │
│  │  Orion   │ │  Cortex  │ │  Nexus   │ │   Axon   │  │
│  │ Laptop   │ │ AI Server│ │ Homelab  │ │   HTPC   │  │
│  │  Niri    │ │ RTX 5090 │ │ Jellyfin │ │ Jellyfin │  │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘  │
│                                                        │
│                    ┌──────────┐                         │
│                    │ Synology │                         │
│                    │ DS-920+  │                         │
│                    │ (Backup) │                         │
│                    └──────────┘                         │
└────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
.
├── flake.nix                  # Main flake definition
├── flake.lock                 # Locked dependency versions
├── README.md                  # Quick reference
├── SECRETS.md                 # Secrets management guide
├── ISSUES.md                  # Bug tracker
├── CONTRIBUTING.md            # Development workflow
│
├── systems/                   # Per-system configurations
│   ├── orion/                 # Workstation (Framework 13)
│   ├── cortex/                # AI server (RTX 5090)
│   ├── nexus/                 # Homelab server
│   ├── axon/                  # HTPC
│   └── custom-live-iso/       # Live ISO for bootstrapping
│
├── modules/
│   ├── features/              # 35+ unified feature modules
│   │   ├── niri.nix           # Wayland compositor + config
│   │   ├── noctalia-shell.nix # Desktop shell (Quickshell-based)
│   │   ├── git.nix            # Git + user config
│   │   ├── audio.nix          # PipeWire + WirePlumber
│   │   ├── ai-services/       # Cortex AI/ML stack
│   │   └── ...
│   ├── system/                # Base system configuration
│   └── home/                  # Home Manager base layers
│
├── scripts/                   # Utility scripts
│   ├── bootstrap/             # System bootstrapping
│   ├── deployment/            # Pre-flight, validation
│   ├── desktop/               # Monitor, screenshot, volume
│   ├── development/           # Dev environment setup
│   ├── security/              # Scanning, key rotation
│   └── testing/               # VM and container testing
│
├── docs/                      # Documentation
│   ├── ARCHITECTURE.md        # Module system reference
│   ├── DENDRITIC-MIGRATION.md # Feature module architecture
│   ├── BOOTSTRAP.md           # Bootstrapping new systems
│   ├── PROJECT-OVERVIEW.md    # This file
│   ├── security/              # Security docs
│   ├── planning/              # Planning and roadmap
│   └── archive/               # Historical docs
│
├── dotfiles/                  # Config files (symlinked by home-manager)
├── wallpapers/                # Desktop backgrounds
└── shells/                    # Development shells (devenv)

[Separate Repository]
nixos-secrets/                 # Private secrets (git submodule)
    ├── secrets.yaml           # Encrypted secrets (sops)
    ├── .sops.yaml             # Encryption configuration
    └── keys/hosts/            # Per-host age keys
```

---

## Technical Stack

### Core

- **NixOS** with Nix Flakes
- **Home Manager** for user environments
- **sops-nix** with age encryption for secrets
- **fleet CLI** ([nixos-fleet](https://github.com/sygint/nixos-fleet)) for deployment
- **Colmena** for parallel deployment (migration in progress)
- **disko** for declarative disk partitioning
- **nixos-anywhere** for remote installation

### Desktop (Orion)

- **Niri** scrollable tiling Wayland compositor
- **Noctalia Shell** desktop shell (Quickshell-based, status bar + dock + launcher)
- **Ghostty** terminal (GPU accelerated)
- **Dank Material Shell** alternative Quickshell-based shell (available)

### AI/ML (Cortex)

- **NVIDIA RTX 5090** with CUDA drivers
- **Ollama** for LLM inference
- AI services configured via `modules/features/ai-services/`

### Media and Entertainment

- **Jellyfin** media server on Nexus, kiosk client on Axon
- **Moonlight/Sunshine** game streaming (planned)

- SSH key-only auth with hardened config
- fail2ban + auditd on servers
- Mullvad VPN integration
- git-secrets + TruffleHog pre-commit scanning
- Full disk encryption on Orion

---

## Module System

The dendritic pattern: one feature module per concern, containing both system and user configuration.

```nix
# systems/orion/default.nix
modules.features = {
  niri.enable = true;
  noctalia-shell.enable = true;
  git.enable = true;
  vscode.enable = true;
  audio.enable = true;
  bluetooth.enable = true;
  mullvad.enable = true;
};
```

All features use the `modules.features.*` namespace. Each module is self-contained with its own packages, services, and home-manager config. Features never auto-enable.

See [docs/DENDRITIC-MIGRATION.md](docs/DENDRITIC-MIGRATION.md) for the full architecture guide and [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for module creation patterns.

---

## Deployment

```bash
# Local rebuild (preferred)
nos                    # alias for 'nh os switch'

# Or explicitly
sudo nixos-rebuild switch --flake .#orion

# Remote deployment (auto-syncs secrets)
fleet push cortex
fleet push all

# Health check
fleet check cortex

# Fresh install (wipes disk)
fleet install cortex 192.168.1.7
```

Fleet management provided by [nixos-fleet](https://github.com/sygint/nixos-fleet). Secrets auto-sync before each deploy (`--no-sync` to skip).

---

## Secrets

Managed with sops-nix and age encryption. Host keys derive age keys automatically. The `fleet push` command syncs secrets as part of deployment.

See [SECRETS.md](SECRETS.md) for the complete guide.

---

## Known Issues

See [ISSUES.md](ISSUES.md) for the current bug tracker. Key open items:

- Bluetooth audio channel switching not working properly
- Mullvad VPN tray icon not loading (Electron/Wayland upstream issue)
- sshd status reporting inconsistency on Cortex

---

## Status

### Production Ready

- All 4 systems (Orion, Cortex, Nexus, Axon) deployed and operational
- 35+ unified feature modules in dendritic pattern
- Secrets management with auto-sync on deploy
- Fleet CLI for deployment and health checks
- Security hardening (fail2ban, auditd, SSH hardening)
- Niri + Noctalia Shell desktop with multi-monitor support
- Jellyfin media server (Nexus) with kiosk client (Axon)
- Hardware video acceleration (AMD/NVIDIA)

### In Progress

- Colmena migration for parallel deployment
- Cortex AI/ML service expansion

### Future Ideas

See [docs/planning/TODO.md](docs/planning/TODO.md) for the backlog of aspirational items.

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development workflow and guidelines.

---

## Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Package Search](https://search.nixos.org/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Niri](https://github.com/YaLTeR/niri) -- scrollable tiling Wayland compositor
- [Noctalia Shell](https://github.com/noctalia-dev/noctalia-shell) -- Quickshell-based desktop shell
- [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell) -- Quickshell-based shell
- [sops-nix](https://github.com/Mic92/sops-nix) -- secrets management
- [nixos-fleet](https://github.com/sygint/nixos-fleet) -- fleet management CLI

---

**Last Updated**: February 2026
**NixOS Version**: 24.11 (Unstable)
**Production Ready**: Orion | Cortex | Nexus | Axon
