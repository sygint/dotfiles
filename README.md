# NixOS Configuration

Unified NixOS fleet configuration using the dendritic pattern — one feature module per concern, composable across systems.

## Quick Start

```bash
# Deploy to a remote system
fleet push cortex

# Rebuild locally
nos                    # alias for 'nh os switch'

# Deploy to all systems
fleet push all

# Check system health before deploying
fleet check cortex
```

## Architecture Overview

**Unified Feature Modules** — one file per feature, containing both system and user configuration.

```
modules/
├── features/           # PRIMARY: 30+ unified feature modules
│   ├── hyprland.nix   # Wayland compositor (legacy)
│   ├── niri.nix       # Wayland compositor (current)
│   ├── noctalia-shell.nix # Desktop shell
│   ├── mullvad.nix    # VPN service + browser
│   ├── git.nix        # Git + user config
│   └── ...            # All features in one place
├── system/            # Special-purpose system modules
│   ├── base/          # Essential base configuration
│   └── ai-services/   # Cortex-specific AI services
└── home/              # Home Manager base layers
    ├── _base/         # Essential CLI tools
    └── _base-desktop/ # Desktop environment essentials
```

### Using Features

```nix
# systems/orion/default.nix
modules.features = {
  # Desktop environment
  niri.enable = true;
  noctalia-shell.enable = true;

  # Development tools
  git.enable = true;
  vscode.enable = true;

  # Web browsers
  brave.enable = true;
  firefox.enable = true;

  # Services
  mullvad.enable = true;
  syncthing.enable = true;

  # Infrastructure
  audio.enable = true;
  bluetooth.enable = true;
  networking.enable = true;
};
```

**Benefits:**
- **Single source of truth** — one file per feature
- **Consistent interface** — all use `modules.features.*`
- **Complete configuration** — system + home together
- **Composable** — mix and match across systems

See [docs/DENDRITIC-MIGRATION.md](docs/DENDRITIC-MIGRATION.md) for the full architecture guide.

## Fleet

### Systems

| System | Type | Hardware | IP | User | Status |
|--------|------|----------|----|------|--------|
| **Orion** | Workstation | Framework 13 (AMD 7040) | local | syg | ✅ Active |
| **Cortex** | AI Server | RTX 5090 (32GB VRAM) | 192.168.1.7 | jarvis | ✅ Active |
| **Nexus** | Homelab Server | HP EliteDesk 800 G4 | — | admin | ✅ Active |
| **Axon** | HTPC | Streaming client | — | — | ✅ Active |

### Architecture

```
┌────────────────────────────────┐
│    Orion (Workstation)         │
│  ┌──────────────────────────┐  │
│  │  NixOS Config Repo       │  │
│  │  - flake.nix             │  │
│  │  - systems/              │  │
│  │  - modules/              │  │
│  └──────────────────────────┘  │
└────────────────────────────────┘
          │
          │ fleet push
          ↓
┌──────────────┐  ┌──────────────┐  ┌──────────────┐
│   Cortex     │  │    Nexus     │  │    Axon      │
│  AI Server   │  │   Homelab    │  │    HTPC      │
│ 192.168.1.7  │  │              │  │              │
└──────────────┘  └──────────────┘  └──────────────┘
```

Fleet management is provided by the `fleet` CLI from [nixos-fleet](https://github.com/sygint/nixos-fleet). Migration to Colmena for parallel deployment and tag-based targeting is in progress.

## Adding New Systems

### 1. Create system directory

```bash
mkdir -p systems/newsystem
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

Then create `default.nix` and `hardware.nix` (or copy from an existing system and modify).

### 2. Add to flake.nix

```nix
nixosConfigurations = {
  # ... existing systems ...
  newsystem = nixpkgs.lib.nixosSystem {
    system = "x86_64-linux";
    specialArgs = {
      inherit self system inputs fh userVars hasSecrets;
    };
    modules = withOptionalSecrets [
      ./systems/newsystem
    ];
  };
};
```

### 3. Deploy

```bash
nix build .#nixosConfigurations.newsystem.config.system.build.toplevel
fleet push newsystem
```

See [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) for bootstrapping NixOS on new hardware.

## Secrets

Secrets are managed with [sops-nix](https://github.com/Mic92/sops-nix) and age encryption. Host keys derive age keys automatically, and `fleet push` syncs secrets as part of deployment. See [SECRETS.md](SECRETS.md) for the complete guide including key setup, editing secrets, and rekeying.

## Troubleshooting

### Connection Issues

Can't reach a remote system: verify with `ping <ip>`, then test SSH directly with `ssh user@host "echo ok"`. If SSH fails, check that your key is loaded (`ssh-add -l`) and that `sshd` is running on the target.

### Build Failures

Configuration won't build: run `nix flake check` for syntax errors, then build with `--show-trace` for detailed output:
`nix build .#nixosConfigurations.<system>.config.system.build.toplevel --show-trace`

### Deployment Failures

Deployment hangs or fails: run `fleet check <system>` for pre-flight diagnostics. Check target logs with `ssh user@host "journalctl -xe"`. If the system is in a bad state, roll back with `ssh user@host "sudo nixos-rebuild switch --rollback"`.

### Secrets Issues

Secrets not decrypting on target: verify the host key exists (`/etc/ssh/ssh_host_ed25519_key`), check `systemctl status sops-nix`, and rekey if needed with `fleet secrets rekey`.

## Documentation

- [docs/DENDRITIC-MIGRATION.md](docs/DENDRITIC-MIGRATION.md) — Feature modules architecture
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — Module system reference
- [docs/BOOTSTRAP.md](docs/BOOTSTRAP.md) — Bootstrap new NixOS systems
- [docs/PROJECT-OVERVIEW.md](docs/PROJECT-OVERVIEW.md) — Project architecture and philosophy
- [SECRETS.md](SECRETS.md) — Secrets management (sops-nix + age)
- [docs/security/SECURITY.md](docs/security/SECURITY.md) — Security configuration
- [docs/security/CORTEX-SECURITY.md](docs/security/CORTEX-SECURITY.md) — Cortex hardening
- [systems/cortex/AI-SERVICES.md](systems/cortex/AI-SERVICES.md) — AI/LLM infrastructure
- [CONTRIBUTING.md](CONTRIBUTING.md) — Contributing guidelines

## Design Principles

1. **One Feature, One File** — all configuration for a feature in a single place
2. **Unified Namespace** — all features use `modules.features.*`
3. **Explicit Configuration** — features never auto-enable
4. **Composability** — mix and match features across systems
5. **Parameterization** — configure via `userVars`/`systemVars`
