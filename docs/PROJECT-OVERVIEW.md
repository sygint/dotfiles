# NixOS Configuration - Project Overview

**Personal Infrastructure as Code**  
*A declarative, reproducible, and security-focused NixOS configuration for a privacy-conscious home network*

---

## 🎯 Project Purpose

This is a comprehensive NixOS configuration designed to manage a complete home network infrastructure with emphasis on:

- **Security & Privacy**: No cloud dependencies, full disk encryption where needed, VPN-ready networking, hardened configurations
- **Reproducibility**: Declarative infrastructure that can be version-controlled, rebuilt, and deployed consistently
- **AI/ML Workloads**: GPU-accelerated LLM inference, stable diffusion, and development tooling
- **Development**: Multi-language support (JavaScript, Go, Rust, Zig), containerization ready
- **Entertainment**: Gaming, media streaming (Jellyfin planned), multi-monitor desktop environments
- **Data Backup**: Integration with Synology NAS (DS-920+) for automated backups (planned)
- **Fleet Management**: Centralized configuration management for multiple specialized machines

### Philosophy

This configuration represents a learning journey in the open - combining ideas from the NixOS community while being tailored to specific personal needs. It prioritizes:

1. **Stability over bleeding-edge** - Remote deployments must work reliably
2. **Modularity** - Components should be reusable across different machines
3. **Security by default** - Hardened configurations, minimal attack surface
4. **Privacy-first** - No cloud services, self-hosted infrastructure
5. **Documentation** - Clear explanations for future reference and AI assistants

---

## 🏗️ Infrastructure Overview

### Current Systems

#### **Orion** - Personal Development Workstation
- **Hardware**: Framework 13 laptop with AMD 7040 CPU
- **Role**: Primary development machine for day-to-day work
- **User**: `syg` (main user)
- **Use Cases**: 
  - Software development (JavaScript, Go, Rust, Zig)
  - Multi-monitor desktop with Hyprland (Wayland compositor)
  - Hyprpanel UI (with legacy Waybar support)
  - Remote access to home network
- **Security**: Full disk encryption (for mobile use)
- **Status**: ✅ Active and stable

#### **Cortex** - AI/Gaming Rig
- **Hardware**: Desktop with RTX 5090 GPU
- **Role**: High-performance compute for AI and gaming
- **User**: `jarvis` (admin)
- **Use Cases**:
  - Local LLM inference (ollama, llama.cpp, etc.)
  - Stable diffusion and other AI workloads
  - GPU-accelerated development
  - Game streaming when not computing
- **Security**: SSH hardening, fail2ban, audit logging, auditd
- **Status**: ✅ Deployed and operational (NixOS configuration complete)

### Planned Systems

#### **Proxmox Server**
- **Role**: Virtualization and container host
- **Planned Services**:
  - Home Assistant (home automation)
  - Jellyfin (media server)
  - Additional homelab services
- **Status**: 📋 Planned

#### **Frigate NVR**
- **Role**: Network video recording and security
- **Status**: 📋 Under consideration

### Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Home Network                         │
│                  (192.168.1.0/24)                       │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │    Orion     │  │    Cortex    │  │   Synology   │  │
│  │  (Laptop)    │  │  (AI/Gaming) │  │   DS-920+    │  │
│  │              │  │              │  │   (Backup)   │  │
│  │  Hyprland    │  │  NVIDIA GPU  │  │              │  │
│  │  Development │  │  LLM Inference│  │  Storage    │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │         │
│         └──────────────────┴──────────────────┘         │
│                            │                            │
│                  ┌─────────┴─────────┐                  │
│                  │   VPN Gateway     │                  │
│                  │ (Headscale/Other) │                  │
│                  └───────────────────┘                  │
└─────────────────────────────────────────────────────────┘
                           │
                    [Remote Access]
```

---

## 📁 Repository Structure

```
.
├── flake.nix              # Main flake definition, system registry
├── flake.lock             # Locked dependency versions
├── docs/
│   └── PROJECT-OVERVIEW.md    # This file - comprehensive project documentation
├── README.md              # Quick reference and getting started
├── CONTRIBUTING.md        # Development workflow and guidelines
├── FLEET-MANAGEMENT.md    # Multi-system deployment guide
├── SECRETS.md             # Secrets management with sops-nix
├── docs/SECURITY.md       # Security hardening documentation
│
├── systems/               # Per-system configurations
│   ├── orion/            # Laptop configuration
│   │   ├── default.nix   # System config
│   │   ├── hardware.nix  # Hardware-specific settings
│   │   ├── variables.nix # System/user variables
│   │   ├── homes/        # Per-user home-manager configs
│   │   └── modules/      # System-specific modules (if any)
│   └── cortex/           # AI/Gaming rig configuration
│       ├── default.nix   # System config
│       ├── disk-config.nix  # Disko automated partitioning
│       ├── variables.nix # System/user variables
│       └── modules/      # System-specific modules
│
├── modules/              # Reusable configuration modules
│   ├── system.nix        # System module aggregator
│   ├── home.nix          # Home module aggregator
│   ├── system/           # NixOS system-level modules
│   │   ├── base/         # Essential system foundation
│   │   ├── hardware/     # Audio, Bluetooth, networking, etc.
│   │   ├── services/     # System services (SSH, VPN, etc.)
│   │   ├── windowManagers/  # Hyprland, etc.
│   │   ├── displayServers/  # X11, Wayland
│   │   ├── programs/     # System-wide programs
│   │   └── locale.nix    # Localization settings
│   └── home/             # Home Manager user-level modules
│       ├── base/         # Minimal user profile (CLI tools)
│       ├── base-desktop/ # Desktop user profile (GUI apps)
│       └── programs/     # Individual program modules
│
├── scripts/              # Utility and management scripts
│   ├── deployment/          # Fleet deployment scripts
│   │   ├── safe-deploy.sh   # Safe deployment orchestration
│   │   ├── pre-flight.sh    # Pre-deployment checks
│   │   └── validate.sh      # Post-deployment validation
│   ├── monitor-handler.sh   # Display management
│   ├── start-hyprpanel.sh   # UI launcher
│   ├── screenshot.sh        # Screenshot utilities
│   └── setup-dev-environment.sh  # Dev setup automation
│
├── dotfiles/             # Configuration files (symlinked by home-manager)
│   ├── .config/
│   └── zshenv
│
├── wallpapers/           # Desktop backgrounds
├── examples/             # Reference documentation
├── secrets-example/      # Template for secrets repository
└── shells/               # Development shells (devenv)
    └── node/             # Node.js environment

[Separate Repository]
nixos-secrets/            # Private secrets (git submodule)
    ├── secrets.yaml      # Encrypted secrets (sops)
    ├── .sops.yaml        # Encryption configuration
    └── keys/             # Age encryption keys
        ├── age-key.txt   # Personal key
        └── hosts/        # Per-host keys
```

---

## 🔧 Technical Stack

### Core Technologies

- **NixOS**: Declarative Linux distribution
- **Nix Flakes**: Reproducible, composable configurations
- **Home Manager**: User environment management
- **sops-nix**: Secrets management with age encryption
- **deploy-rs**: Remote system deployment with rollback
- **disko**: Declarative disk partitioning

### Desktop Environment

- **Hyprland**: Wayland compositor (primary)
- **Hyprpanel**: Status bar and system tray
- **Waybar**: Alternative status bar (legacy support)
- **Kitty**: Terminal emulator
- **Rofi**: Application launcher and menus

### Development Tools

- **Languages**: JavaScript/Node.js, Go, Rust, Zig (expanding)
- **Editors**: VS Code (with Nix integration)
- **Version Control**: Git with optimized settings
- **Shell**: Zsh with custom configuration

### AI/ML Stack (Cortex)

- **GPU**: NVIDIA RTX 5090
- **Frameworks**: CUDA, ROCm
- **Inference**: Ollama, llama.cpp, text-generation-webui (planned)
- **Development**: GPU-accelerated coding assistants

### Security & Privacy

- **Encryption**: Age (sops-nix), LUKS (full disk where needed)
- **Firewall**: iptables/nftables via NixOS
- **SSH**: Key-based authentication, hardened configuration
- **Audit**: auditd system call monitoring
- **Intrusion Prevention**: fail2ban
- **VPN**: Headscale (planned) for remote access
- **DNS**: DNS-over-TLS ready (when not using VPN)

### Backup & Storage

- **NAS**: Synology DS-920+
- **Backup Strategy**: Automated backups to NAS (integration planned)
- **Version Control**: Git for configuration, separate for data

---

## 🧩 Module System

This configuration uses a modular architecture where functionality is broken into small, reusable, composable modules organized by purpose.

### Quick Overview

**System Modules** (`modules/system/`):
- **Base**: Core system configuration, Nix settings, user accounts
- **Hardware**: Audio (PipeWire), Bluetooth, networking, printing
- **Services**: SSH, VPN (Mullvad), Syncthing, security services
- **Window Managers**: Hyprland (Wayland), i3 (X11)

**Home Modules** (`modules/home/`):
- **Base**: Shell (zsh), Git, CLI tools (btop, eza, bat)
- **Desktop**: Terminal (kitty), file manager, desktop utilities
- **Programs**: 30+ applications (VS Code, browsers, Discord, etc.)

### Key Features

- **Namespaced**: Custom modules use `modules.programs.*` to avoid conflicts
- **Composable**: Mix and match modules per system
- **Parameterized**: All modules use `userVars` and `systemVars` 
- **Optional**: Everything can be enabled/disabled independently
- **Self-contained**: Each module manages its own packages and config

### Example Usage

```nix
# Minimal CLI system
modules.programs.base.enable = true;

# Full desktop environment
modules.programs = {
  base.enable = true;
  base-desktop.enable = true;
  hyprland.enable = true;
  vscode.enable = true;
  librewolf.enable = true;
};
```

**📖 For detailed module documentation, architecture patterns, and creation guides, see [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md)**

---

## 🚀 Deployment & Management

### Quick Reference

**Local Development (Orion):**
```bash
nh os switch              # Rebuild system
nh home switch           # Update home-manager only
```

**Remote Deployment:**
```bash
fleet status                               # Show all systems
fleet check cortex                         # Health check
fleet push cortex                          # Deploy updates
fleet install cortex 192.168.1.7           # Fresh install (⚠️ wipes disk!)
```

**Tools Used:**
- **nh**: Fast local rebuilds (wrapper for nixos-rebuild)
- **nixos-anywhere**: Initial deployment with disk formatting (disko)
- **deploy-rs**: Safe remote updates with rollback capability
- **fleet**: CLI tool for unified fleet management ([nixos-fleet](https://github.com/sygint/nixos-fleet))

**📖 For detailed deployment procedures, troubleshooting, and fleet management patterns, see [FLEET-MANAGEMENT.md](./FLEET-MANAGEMENT.md)**

---

## 🔐 Secrets Management

### Architecture

- **Public Repo**: Main configuration (this repository)
- **Private Repo**: Encrypted secrets (`nixos-secrets` submodule)
- **Encryption**: Age (sops-nix)
- **Keys**: Per-host and personal age keys

### What Gets Encrypted

- User password hashes
- SSH private keys
- API keys and tokens
- WiFi passwords
- VPN credentials
- Service credentials

### Usage

```nix
# In system configuration
sops.secrets."user/password" = {
  sopsFile = ../../secrets/secrets.yaml;
};

users.users.syg.hashedPasswordFile = config.sops.secrets."user/password".path;
```

### Key Management

```
secrets/keys/
├── age-key.txt       # Personal key (never commit!)
└── hosts/
    ├── orion.txt     # Orion host key
    └── cortex.txt    # Cortex host key
```

See [SECRETS.md](./SECRETS.md) for detailed setup.

---

## 🛡️ Security Hardening

### System-Level Security

- **Kernel Hardening**: Memory protection, ASLR, restricted dmesg
- **Network Security**: SYN cookies, reverse path filtering, ICMP restrictions
- **Firewall**: Enabled by default, minimal open ports
- **SSH Hardening**: Key-only auth, restricted root login, connection timeouts
- **Audit Logging**: System call monitoring for security events
- **Fail2ban**: Automatic IP banning for brute force attempts

### Application Security

- **AppArmor**: Application sandboxing (planned)
- **Minimal Surface**: Only install necessary packages
- **Reproducible**: Locked dependencies prevent supply chain attacks

### Privacy Measures

- **No Telemetry**: Disabled across all applications
- **Local-First**: No cloud dependencies
- **VPN-Ready**: Headscale for secure remote access
- **DNS Privacy**: DNS-over-TLS capable

See [docs/SECURITY.md](./docs/SECURITY.md) for comprehensive security documentation.

---

## 🎨 Desktop Configuration

### Hyprland (Wayland)

- **Compositor**: Hyprland with custom keybindings
- **Status Bar**: Hyprpanel (primary), Waybar (fallback)
- **Launcher**: Rofi with custom theming
- **Terminal**: Kitty with GPU acceleration
- **Screenshots**: Custom script with upload support

### Multi-Monitor Support

Dynamic monitor configuration via `monitors.json`:
- Automatic display detection
- Resolution and refresh rate management
- Position and rotation support
- Hotplug handling

### Theming

- Wallpapers managed in `wallpapers/`
- Consistent color schemes across applications
- Font management via Home Manager

---

## 🔄 Development Workflow

### Making Changes

1. **Edit configuration files** in `systems/` or `modules/`
2. **Test locally**: `nix flake check`
3. **Build**: `nix build .#nixosConfigurations.<system>.config.system.build.toplevel`
4. **Deploy locally**: `nh os switch` (on same machine)
5. **Deploy remotely**: `fleet push <system>`

### Adding New System

1. Create directory: `systems/newsystem/`
2. Create `default.nix`, `hardware.nix`, `variables.nix`
3. Add to `flake.nix` in `nixosConfigurations`
4. Optionally add to `deploy.nodes` for remote deployment
5. Generate hardware config: `nixos-generate-config --dir systems/newsystem`

### Adding New Module

1. Create module file in `modules/system/` or `modules/home/`
2. Define options with `mkEnableOption` and `mkOption`
3. Implement configuration with `mkIf cfg.enable`
4. Import module in `modules/system.nix` or `modules/home.nix`
5. Enable in system configuration

### Pre-commit Validation

Git hooks automatically check:
- Nix syntax errors
- Import validation
- Security configuration
- Secrets detection
- Code formatting

Setup: `./scripts/setup-dev-environment.sh`

---

## 📚 Learning Resources

### Official Documentation

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Package Search](https://search.nixos.org/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Nix Language Basics](https://nixos.org/manual/nix/stable/language/)

### Community Resources

- [NixOS Discourse](https://discourse.nixos.org/)
- [NixOS Wiki](https://nixos.wiki/)
- [Zero to Nix](https://zero-to-nix.com/)

### Tools Used

- [deploy-rs](https://github.com/serokell/deploy-rs) - Deployment tool
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) - Remote installation
- [sops-nix](https://github.com/Mic92/sops-nix) - Secrets management
- [disko](https://github.com/nix-community/disko) - Disk partitioning
- [Hyprland](https://hyprland.org/) - Wayland compositor

---

## 🚧 Known Issues & Limitations

### Current Challenges

1. **Deployment Reliability** (Priority: P0 Critical)
   - No automatic rollback configured in deploy-rs
   - Network/SSH configuration changes risk losing remote access
   - Pre-flight validation scripts exist but not integrated into main workflow
    - Secrets auto-sync on deploy via `fleet push` (`--no-sync` to skip)
   - Risk: Remote deployments can brick systems without easy recovery
   - Solution: Implement safe-deploy wrapper with auto-rollback (see ANALYSIS-SUMMARY.md)
   - Status: High priority fix needed

2. **Backup Integration**: Synology NAS not yet integrated
   - Current: Only synology-drive-client package installed
   - Plan: Borg/Restic automated backups for all systems
   - Status: Planned (see docs/SECURITY-ROADMAP.md)

3. **Mesh VPN Setup**: Headscale not yet configured
   - Current: Using Mullvad VPN for privacy/security
   - Goal: Self-hosted Headscale for secure remote access to home network
   - Use case: Access home services remotely without exposing ports
   - Status: Under evaluation

4. **LibreWolf Stylix Warning**: Profile names not configured
   - Warning: `config.stylix.targets.librewolf.profileNames` not set
   - Status: Minor, non-blocking

5. **Security Services Not Running on Cortex**
   - fail2ban not accessible/running
   - auditd not accessible/running  
   - Services configured but need verification
   - Status: Needs investigation

6. **Minor UI/UX Issues**
   - Hyprlock occasionally crashes
   - Volume notifications showing duplicates
   - Mullvad VPN not appearing in system tray
   - Status: Low priority polish items

### Recent Improvements

- ✅ Added AMD GPU hardware video acceleration (October 29, 2025)
  - Resolved YouTube/streaming video lag in Brave browser
  - See docs/fixes/2025-10-29-brave-hardware-acceleration.md
- ✅ Fixed SOPS age key mismatch for orion (October 27, 2025)
- ✅ Updated Hyprland to latest version
- ✅ Fleet management script with 12 health check steps
- ✅ Cortex fully deployed with security hardening
- ✅ Comprehensive security documentation (docs/CORTEX-SECURITY.md)

---

## 📊 Current Status & Roadmap

### ✅ Production Ready (Working Now)

**Infrastructure:**
- ✅ Orion (Laptop) - Daily driver workstation
- ✅ Cortex (AI/Gaming) - Deployed and operational
- ✅ Fleet management with health checks
- ✅ Secrets management (sops-nix + age encryption)

**Desktop Environment:**
- ✅ Hyprland Wayland compositor with Hyprpanel
- ✅ Multi-monitor support with dynamic configuration
- ✅ Hardware video acceleration (AMD/NVIDIA)
- ✅ Custom keybindings and window rules

**Development Tools:**
- ✅ Multi-language support (JS, Go, Rust, Zig)
- ✅ VS Code with NixOS integration
- ✅ Git workflows and SSH configuration
- ✅ Containerization ready

**Security:**
- ✅ SSH hardening with key-based auth
- ✅ Firewall configuration
- ✅ Full disk encryption (Orion)
- ✅ Mullvad VPN integration
- ✅ Audit logging (auditd)

**Modularity:**
- ✅ 30+ reusable modules
- ✅ System/Home Manager separation
- ✅ Variable-based parameterization
- ✅ Comprehensive architecture documentation

### ⚠️ In Progress (Partially Complete)

**Deployment Safety:**
- ⚠️ Pre-flight/validation scripts exist but not integrated
- ⚠️ No automatic rollback in deploy-rs
- ✅ Automatic secrets sync on deploy
- 🎯 **Next**: Implement safe-deploy wrapper (IMPLEMENTATION-GUIDE.md Day 1-2)

**AI/ML Stack (Cortex):**
- ⚠️ NVIDIA RTX 5090 configured
- ⚠️ CUDA/GPU drivers installed
- ⚠️ Ollama/llama.cpp planned but not deployed
- 🎯 **Next**: Deploy LLM inference services

**Security Hardening:**
- ⚠️ fail2ban/auditd configured but need verification
- ⚠️ AppArmor sandboxing planned
- 🎯 **Next**: Verify security services on Cortex

### 📋 Planned (Not Yet Started)

**Backup & Recovery:**
- 📋 Synology NAS integration (hardware ready)
- 📋 Borg automated backups
- 📋 Disaster recovery procedures

**Remote Access:**
- 📋 Headscale self-hosted mesh VPN
- 📋 Secure remote access to home network
- 📋 No public port exposure

**Homelab Expansion:**
- 📋 Proxmox server for virtualization
- 📋 Jellyfin media server
- 📋 Home Assistant automation
- 📋 Frigate NVR (under consideration)

**Development Workflow:**
- 📋 Pre-commit hooks (nixfmt, statix, deadnix)
- 📋 CI/CD for configuration testing

**See [IMPLEMENTATION-GUIDE.md](IMPLEMENTATION-GUIDE.md) for prioritized implementation timeline (Day 1-10)**

---

## 🎯 Future Roadmap

### Short Term (Next Month)

- [ ] Integrate Synology Borg backups for all systems
- [ ] Complete Cortex AI/ML stack (Ollama, llama.cpp)
- [ ] Set up Headscale VPN for remote access
- [ ] Add pre-commit hooks (nixfmt, statix, deadnix)

### Medium Term (3-6 Months)

- [ ] Deploy Proxmox server for homelab
- [ ] Set up Jellyfin media server
- [ ] Configure Home Assistant
- [ ] Implement Frigate NVR (if needed)
- [ ] Expand module library with new programs
- [ ] Add more comprehensive testing

### Long Term (6+ Months)

- [ ] Multi-user configurations on shared systems
- [ ] Automated system health monitoring
- [ ] CI/CD pipeline for configuration testing
- [ ] Comprehensive backup and disaster recovery
- [ ] Documentation for others to use/fork

---

## 🤝 Contributing

While this is a personal configuration, contributions and suggestions are welcome:

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** your changes thoroughly
4. **Submit** a pull request with clear description

See [CONTRIBUTING.md](./CONTRIBUTING.md) for detailed guidelines.

---

## 📄 License

This configuration is open source for learning and inspiration. Feel free to:
- Use as reference for your own configurations
- Fork and adapt to your needs
- Share with others learning NixOS

No warranty provided - use at your own risk.

---

## 🙏 Acknowledgments

This configuration builds upon ideas and code from the NixOS community:

- Various NixOS configurations on GitHub
- Hyprland community configurations
- Home Manager module examples
- Security hardening guides

Thank you to everyone who shares their NixOS knowledge openly!

---

## 📞 Contact & Support

- **GitHub**: [sygint/dotfiles](https://github.com/sygint/dotfiles)
- **Issues**: Use GitHub issues for bugs or questions
- **Discussions**: GitHub Discussions for general questions

---

**Last Updated**: October 29, 2025  
**NixOS Version**: 24.11 (Unstable)  
**Configuration Status**: Active Development  
**Production Ready**: Orion ✅ | Cortex ✅
