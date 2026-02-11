# Documentation Index

Complete guide to this NixOS configuration. Start here for navigation.

## 🚀 Getting Started

**New to this config?** Start here:
1. Read [README.md](README.md) - Project overview and quick start
2. Check [FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md) - How to deploy systems
3. Review [docs/security/SECURITY.md](docs/security/SECURITY.md) - Security baseline

## 📚 Core Documentation

### Essential Guides

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [README.md](README.md) | Project overview, architecture, quick start | First-time setup, understanding structure |
| [FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md) | Deploy and manage multiple NixOS systems | Initial deployment, routine updates |
| [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) | Bootstrap new NixOS systems from scratch | Installing NixOS on new hardware |
| [systems/cortex/AI-SERVICES.md](systems/cortex/AI-SERVICES.md) | AI/LLM infrastructure on Cortex (Ollama, NVIDIA) | Using AI services, GPU troubleshooting |
| [docs/security/SECURITY.md](docs/security/SECURITY.md) | Security configuration (fail2ban, auditd, SSH) | Hardening systems, security audit |
| [SECRETS.md](SECRETS.md) | Complete secrets management guide with sops-nix | Managing passwords, API keys, certificates |

## � Planning & Implementation

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [docs/PROJECT-OVERVIEW.md](docs/PROJECT-OVERVIEW.md) | Architecture, philosophy, system details | Understanding design decisions |
| [docs/ROADMAP.md](docs/ROADMAP.md) | Implementation roadmap and timeline | Planning next features |
| [docs/IMPLEMENTATION-GUIDE.md](docs/IMPLEMENTATION-GUIDE.md) | Step-by-step implementation guides | Adding new features |
| [docs/planning/TODO-CHECKLIST.md](docs/planning/TODO-CHECKLIST.md) | Progress tracking and status | Tracking what's done |

## �🛠️ Troubleshooting & Reference

### Troubleshooting Guides

- [Brave Browser Issues](docs/troubleshooting/brave.md) - Browser optimization and troubleshooting

### Blog & Learning

- [Fixing Deployment Hell](docs/blog/2025-10-15-fixing-deployment-hell.md) - Journey to safe deployments

## 🗺️ Quick Reference

### Common Tasks

**Deploy to a system:**
```bash
fleet push cortex
```

**Update all systems:**
```bash
fleet push all
```

**Check AI services:**
```bash
ssh jarvis@192.168.1.7 "systemctl status ollama"
```

**Access LLM on Cortex:**
```bash
export OLLAMA_HOST=http://192.168.1.7:11434
ollama run llama3.2:3b
```

### System Information

| System | Hostname | IP | Purpose | Admin User |
|--------|----------|----|---------|-----------| 
| Orion | orion | 192.168.1.x | Workstation (Framework 13) | syg |
| Cortex | cortex | 192.168.1.7 | AI Server (RTX 5090) | jarvis |

## 📖 Documentation Standards

### Contributing to Docs

When updating documentation:
1. **Single Source of Truth** - Each topic in ONE place only
2. **Practical Focus** - Show what and how, explain why only when non-obvious
3. **Keep Updated** - Delete outdated content, don't just mark as "resolved"
4. **Cross-reference** - Link related docs, update this index

### Structure

```
├── README.md              # Overview & quick start
├── DOCS.md                # This file - master index
├── CONTRIBUTING.md        # How to contribute
├── FLEET-MANAGEMENT.md    # Deployment guide
├── SECRETS.md             # Secrets management
├── docs/
│   ├── PROJECT-OVERVIEW.md       # Architecture & philosophy
│   ├── ROADMAP.md                # Implementation timeline
│   ├── IMPLEMENTATION-GUIDE.md   # Step-by-step guides
│   ├── ARCHITECTURE.md           # Module system docs
│   ├── BOOTSTRAP.md              # Bootstrap new systems
│   ├── FLEET-FUTURE.md           # Future fleet tools (Colmena)
│   ├── planning/                 # Planning & tracking docs
│   │   ├── TODO-CHECKLIST.md     # Progress tracking
│   │   ├── CLEANUP-PRD.md        # Cleanup project details
│   │   └── CLEANUP-CHECKLIST.md  # Cleanup tasks
│   ├── security/                 # Security documentation
│   │   ├── SECURITY.md           # Security configuration
│   │   ├── SECURITY-ROADMAP.md   # Security roadmap
│   │   ├── SECURITY-SCANNING.md  # Secret scanning
│   │   └── CORTEX-SECURITY.md    # Cortex hardening
│   ├── troubleshooting/          # Specific issue guides
│   └── blog/                     # Learning journey posts
└── systems/
    └── cortex/
        └── AI-SERVICES.md        # AI infrastructure (Cortex-specific)
```

## 🔗 External Resources

### NixOS Learning
- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Pills](https://nixos.org/guides/nix-pills/) - Deep dive tutorial
- [Home Manager Manual](https://nix-community.github.io/home-manager/)

### Tools Used
- [deploy-rs](https://github.com/serokell/deploy-rs) - Remote deployment
- [Colmena](https://github.com/zhaofengli/colmena) - Fleet management
- [nixos-anywhere](https://github.com/nix-community/nixos-anywhere) - Remote installation
- [sops-nix](https://github.com/Mic92/sops-nix) - Secrets management

### Inspiration
- [EmergentMind/nix-config](https://github.com/EmergentMind/nix-config) - Production patterns
- [m3tam3re/nixcfg](https://github.com/m3tam3re/nixcfg) - Tutorial approach

---

**Last Updated:** October 20, 2025  
**Config Version:** 25.11 (Xantusia)
