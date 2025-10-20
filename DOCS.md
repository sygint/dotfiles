# Documentation Index

Complete guide to this NixOS configuration. Start here for navigation.

## 🚀 Getting Started

**New to this config?** Start here:
1. Read [README.md](README.md) - Project overview and quick start
2. Check [FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md) - How to deploy systems
3. Review [SYSTEM-SECURITY.md](SYSTEM-SECURITY.md) - Security baseline

## 📚 Core Documentation

### Essential Guides

| Document | Purpose | When to Use |
|----------|---------|-------------|
| [README.md](README.md) | Project overview, architecture, quick start | First-time setup, understanding structure |
| [FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md) | Deploy and manage multiple NixOS systems | Initial deployment, routine updates |
| [AI-SERVICES.md](AI-SERVICES.md) | AI/LLM infrastructure on Cortex (Ollama, NVIDIA) | Using AI services, GPU troubleshooting |
| [SYSTEM-SECURITY.md](SYSTEM-SECURITY.md) | Security configuration (fail2ban, auditd, SSH) | Hardening systems, security audit |
| [SECRETS-SETUP.md](SECRETS-SETUP.md) | Secrets management with sops-nix | Managing passwords, API keys, certificates |

## 🛠️ Troubleshooting & Reference

### Troubleshooting Guides

- [Brave Browser Issues](docs/troubleshooting/brave.md) - Browser optimization and troubleshooting

### Blog & Learning

- [Fixing Deployment Hell](docs/blog/2025-10-15-fixing-deployment-hell.md) - Journey to safe deployments

## 🗺️ Quick Reference

### Common Tasks

**Deploy to a system:**
```bash
./scripts/fleet.sh deploy cortex
```

**Update all systems:**
```bash
./scripts/fleet-deploy.sh update --all
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
├── FLEET-MANAGEMENT.md    # Deployment guide
├── AI-SERVICES.md         # AI infrastructure
├── SYSTEM-SECURITY.md     # Security configuration
├── SECRETS-SETUP.md       # Secrets management
└── docs/
    ├── troubleshooting/   # Specific issue guides
    └── blog/              # Learning journey posts
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
