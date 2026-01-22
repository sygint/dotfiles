# Dendritic Migration Guide

**Unified Feature Modules - Complete Migration Documentation**

---

## Table of Contents

1. [Overview](#overview)
2. [What Changed](#what-changed)
3. [Design Philosophy](#design-philosophy)
4. [New Architecture](#new-architecture)
5. [Migration Results](#migration-results)
6. [Using Feature Modules](#using-feature-modules)
7. [Creating New Features](#creating-new-features)
8. [Comparison: Before vs After](#comparison-before-vs-after)
9. [Benefits](#benefits)
10. [Related Documentation](#related-documentation)

---

## Overview

The **dendritic migration** transformed this NixOS configuration from a split system/home module architecture to a **unified feature modules pattern**. Each feature is now defined in a single file that handles both system-level and user-level configuration.

**Completed**: January 22, 2026  
**Modules Migrated**: 30  
**Code Removed**: 1,452 lines  
**PRs Merged**: 6 (#28-33)

### What is "Dendritic"?

The dendritic pattern follows the principle: **"One best way to configure each feature."**

Instead of splitting configuration between `modules/system/` and `modules/home/`, each feature lives in a single file under `modules/features/`. This eliminates duplication, reduces cognitive overhead, and creates a single source of truth.

Inspired by: [github.com/mightyiam/dendritic](https://github.com/mightyiam/dendritic)

---

## What Changed

### Before Migration

```
modules/
├── system/
│   ├── services/mullvad.nix          # System config
│   ├── windowManagers/hyprland.nix   # System config
│   └── hardware/audio.nix            # System config
└── home/
    ├── programs/mullvad.nix          # User config
    ├── programs/hyprland.nix         # User config
    └── programs/audio.nix            # User config (maybe?)
```

**Problems:**
- Feature config split across two files
- Unclear which file to edit
- Duplicate imports in systems
- Inconsistent namespacing

### After Migration

```
modules/
├── features/                # ✅ Single source of truth
│   ├── mullvad.nix         # System + Home config
│   ├── hyprland.nix        # System + Home config
│   ├── audio.nix           # System + Home config
│   └── ...                 # 30 unified modules
├── system/                 # Special-purpose only
│   ├── base/               # Essential base config
│   └── ai-services/        # Cortex-specific
└── home/
    ├── _base/              # Base home config
    └── _base-desktop/      # Desktop base config
```

**Benefits:**
- One file per feature
- Clear ownership
- Consistent namespace: `modules.features.*`
- Easier to understand and maintain

---

## Design Philosophy

### 1. One Feature, One File

Each feature module is **self-contained** and handles all aspects of that feature:
- System-level configuration (services, packages, etc.)
- User-level configuration (dotfiles, user packages)
- Optional dependencies or sub-features

### 2. Consistent Namespace

All feature modules use the same namespace pattern:

```nix
modules.features.<feature-name>.enable = true;
```

**Examples:**
```nix
modules.features.hyprland.enable = true;
modules.features.mullvad.enable = true;
modules.features.git.enable = true;
```

### 3. Explicit Over Implicit

Features are **never auto-enabled**. Each system explicitly declares what it needs:

```nix
# systems/orion/default.nix
modules.features = {
  hyprland.enable = true;
  mullvad.enable = true;
  git.enable = true;
  # ... only what this system needs
};
```

### 4. Composability

Features can be mixed and matched across systems without conflicts:

```nix
# Minimal server
modules.features.git.enable = true;

# Full workstation
modules.features = {
  git.enable = true;
  hyprland.enable = true;
  vscode.enable = true;
  brave.enable = true;
};
```

---

## New Architecture

### Directory Structure

```
modules/
├── features/                    # 🎯 UNIFIED FEATURE MODULES
│   ├── Core
│   │   ├── zsh.nix             # Shell configuration
│   │   ├── mullvad.nix         # VPN service + browser
│   │   └── git.nix             # Git + user config
│   ├── Hyprland Ecosystem
│   │   ├── hyprland.nix        # WM + compositor
│   │   ├── hyprpanel.nix       # Status bar
│   │   ├── hypridle.nix        # Idle management
│   │   ├── waybar.nix          # Alternative status bar
│   │   └── screenshots.nix     # Screenshot tools
│   ├── Development Tools
│   │   ├── kitty.nix           # Terminal emulator
│   │   ├── btop.nix            # System monitor
│   │   ├── devenv.nix          # Development environments
│   │   └── vscode.nix          # Code editor
│   ├── Web Browsers
│   │   ├── brave.nix           # Chromium-based
│   │   ├── firefox.nix         # Mozilla
│   │   └── librewolf.nix       # Privacy-focused
│   ├── Utilities
│   │   ├── archiver.nix        # Archive tools
│   │   └── protonmail-bridge.nix
│   ├── System Services
│   │   ├── containerization.nix # Docker/Podman
│   │   ├── virtualization.nix   # libvirt/QEMU
│   │   ├── flatpak.nix         # Flatpak support
│   │   ├── printing.nix        # CUPS
│   │   ├── xserver.nix         # X11 support
│   │   └── syncthing.nix       # File sync
│   └── Infrastructure
│       ├── audio.nix           # PipeWire
│       ├── bluetooth.nix       # Bluez
│       ├── networking.nix      # NetworkManager
│       ├── nix-helpers.nix     # Nix utilities
│       ├── wayland.nix         # Wayland support
│       ├── security.nix        # Security tools
│       └── monitor-tools.nix   # System monitoring
│
├── system/                     # 🔒 SPECIAL-PURPOSE SYSTEM MODULES
│   ├── base/                   # Essential base config (always-on)
│   ├── ai-services/            # Cortex-specific AI/LLM services
│   ├── kanboard.nix            # Cortex-specific project management
│   ├── locale.nix              # Always-on locale configuration
│   └── system/
│       └── secrets-password-sync.nix  # Password sync service
│
└── home/                       # 🏠 HOME MANAGER BASE LAYERS
    ├── _base/                  # Essential CLI tools (zsh, git, etc.)
    └── _base-desktop/          # Desktop environment essentials
```

### Module Categories

#### Feature Modules (`modules/features/`)

**30 unified feature modules** - The primary way to configure functionality:

| Category | Modules | Purpose |
|----------|---------|---------|
| **Core** | zsh, mullvad, git | Essential daily tools |
| **Hyprland** | hyprland, hyprpanel, hypridle, waybar, screenshots | Wayland desktop environment |
| **Development** | kitty, btop, devenv, vscode | Development tools |
| **Browsers** | brave, firefox, librewolf | Web browsers |
| **Utilities** | archiver, protonmail-bridge | Specialized tools |
| **Services** | containerization, virtualization, flatpak, printing, xserver, syncthing | System services |
| **Infrastructure** | audio, bluetooth, networking, nix-helpers, wayland, security, monitor-tools | Core system infrastructure |

#### Special-Purpose Modules

**Base Layers** - Always-on foundation:
- `modules/system/base/` - Boot loader, Nix settings, core packages
- `modules/home/_base/` - Essential CLI tools for all systems
- `modules/home/_base-desktop/` - Desktop environment essentials

**System-Specific** - Not migrated (by design):
- `modules/system/ai-services/` - Cortex AI/LLM infrastructure
- `modules/system/kanboard.nix` - Cortex project management
- `modules/system/locale.nix` - System-wide localization
- `modules/system/system/secrets-password-sync.nix` - Password management

---

## Migration Results

### Statistics

| Metric | Before | After | Change |
|--------|--------|-------|--------|
| **Feature modules** | 0 | 30 | +30 |
| **Split modules** | 25 | 0 | -25 |
| **Total files** | 55 | 30 | -45% |
| **Lines of code** | ~3,200 | ~1,748 | -1,452 (-45%) |
| **Namespaces** | 5 inconsistent | 1 unified | Standardized |

### Pull Requests

1. **PR #28** - Hotfix: Remove accidentally committed homelab-services
2. **PR #29** - Migrate utilities (archiver, protonmail-bridge)
3. **PR #30** - Migrate system services (6 modules)
4. **PR #31** - Batch 1: Foundational modules (5 modules)
5. **PR #32** - Batch 2: Final Phase 2 (2 modules) - **Phase 2 Complete**
6. **PR #33** - Phase 3: Cleanup obsolete files - **Migration Complete**

### All Migrated Modules

**Core Features (3):**
- zsh, mullvad, git

**Hyprland Ecosystem (5):**
- hyprland, hyprpanel, hypridle, waybar, screenshots

**Development Tools (4):**
- kitty, btop, devenv, vscode

**Web Browsers (3):**
- brave, firefox, librewolf

**Utilities (2):**
- archiver, protonmail-bridge

**System Services (6):**
- containerization, virtualization, flatpak, printing, xserver, syncthing

**Infrastructure (7):**
- audio, bluetooth, networking, nix-helpers, wayland, security, monitor-tools

---

## Using Feature Modules

### Enabling Features

Feature modules are enabled in system configurations using the unified namespace:

```nix
# systems/orion/default.nix
{ ... }:
{
  modules.features = {
    # Core
    zsh.enable = true;
    mullvad.enable = true;
    git.enable = true;
    
    # Desktop environment
    hyprland.enable = true;
    hyprpanel.enable = true;
    hypridle.enable = true;
    waybar.enable = true;
    screenshots.enable = true;
    
    # Development
    kitty.enable = true;
    btop.enable = true;
    devenv.enable = true;
    vscode.enable = true;
    
    # Browsers
    brave.enable = true;
    firefox.enable = true;
    librewolf.enable = true;
    
    # Services
    syncthing.enable = true;
    printing.enable = true;
    containerization.enable = true;
    
    # Infrastructure
    audio.enable = true;
    bluetooth.enable = true;
    networking = {
      enable = true;
      hostName = "orion";
    };
    wayland.enable = true;
    security.enable = true;
  };
}
```

### Per-System Configuration

Each system can enable different feature combinations:

**Orion (Workstation):**
```nix
modules.features = {
  # Full desktop + development stack
  hyprland.enable = true;
  vscode.enable = true;
  brave.enable = true;
  mullvad.enable = true;
  # ... 20+ features
};
```

**Cortex (AI Server):**
```nix
modules.features = {
  # Minimal server setup
  git.enable = true;
  containerization.enable = true;
  security.enable = true;
  # No desktop environment
};
```

**Nexus (Homelab):**
```nix
modules.features = {
  # Server basics + monitoring
  git.enable = true;
  syncthing.enable = true;
  monitor-tools.enable = true;
};
```

### Feature Options

Many feature modules accept additional configuration:

```nix
modules.features = {
  # Simple enable
  git.enable = true;
  
  # With options
  networking = {
    enable = true;
    hostName = "my-system";
  };
  
  # Complex configuration
  hyprland = {
    enable = true;
    # Additional Hyprland-specific options
  };
};
```

---

## Creating New Features

### Feature Module Template

```nix
# modules/features/my-feature.nix
{
  config,
  lib,
  pkgs,
  userVars,  # User variables (username, email, etc.)
  ...
}:

let
  inherit (lib) mkEnableOption mkOption mkIf types;
  cfg = config.modules.features.my-feature;
in
{
  options.modules.features.my-feature = {
    enable = mkEnableOption "My Feature";
    
    # Optional: Additional feature options
    someOption = mkOption {
      type = types.str;
      default = "default-value";
      description = "Description of this option";
    };
  };

  config = mkIf cfg.enable {
    # ===== SYSTEM-LEVEL CONFIG =====
    
    # System packages
    environment.systemPackages = with pkgs; [
      my-package
    ];
    
    # System services
    systemd.services.my-service = {
      enable = true;
      description = "My Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.my-package}/bin/my-service";
        Restart = "always";
      };
    };
    
    # ===== USER-LEVEL CONFIG =====
    
    # Home-manager configuration
    home-manager.users.${userVars.username} = {
      # User packages
      home.packages = with pkgs; [
        my-user-tool
      ];
      
      # User configuration files
      home.file.".config/my-app/config.toml".text = ''
        setting = "${cfg.someOption}"
        username = "${userVars.username}"
      '';
      
      # XDG configuration
      xdg.configFile."my-app/settings.json".source = ./my-app-settings.json;
    };
  };
}
```

### Steps to Create a New Feature

1. **Create the module file**
   ```bash
   touch modules/features/my-feature.nix
   ```

2. **Define the module** using the template above

3. **No imports needed!** The module is automatically discovered and loaded

4. **Enable in system config**
   ```nix
   # systems/orion/default.nix
   modules.features.my-feature.enable = true;
   ```

5. **Test the configuration**
   ```bash
   nix flake check --no-build
   nixos-rebuild build --flake .#orion
   ```

6. **Apply the changes**
   ```bash
   sudo nixos-rebuild switch --flake .#orion
   ```

### Best Practices

1. **Single Responsibility**: Each feature module should handle one logical feature
2. **Self-Contained**: Include all packages, configs, and services for the feature
3. **Optional by Default**: Always use `mkIf cfg.enable` to make features optional
4. **Use Variables**: Leverage `userVars` and `systemVars` for parameterization
5. **Document Options**: Provide clear descriptions for all options
6. **Sensible Defaults**: Provide good defaults, allow overrides

### Feature Module Patterns

**System-Only Feature:**
```nix
config = mkIf cfg.enable {
  # Only system-level configuration
  services.my-service.enable = true;
  environment.systemPackages = [ pkgs.my-package ];
};
```

**Home-Only Feature:**
```nix
config = mkIf cfg.enable {
  # Only user-level configuration
  home-manager.users.${userVars.username} = {
    home.packages = [ pkgs.my-app ];
    xdg.configFile."my-app/config".source = ./config;
  };
};
```

**Hybrid Feature (Most Common):**
```nix
config = mkIf cfg.enable {
  # System configuration
  services.my-service.enable = true;
  
  # User configuration
  home-manager.users.${userVars.username} = {
    programs.my-app.enable = true;
  };
};
```

---

## Comparison: Before vs After

### Before: Split Modules

**System Module** (`modules/system/services/mullvad.nix`):
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.services.mullvad;
in
{
  options.modules.services.mullvad.enable = lib.mkEnableOption "Mullvad VPN";

  config = lib.mkIf cfg.enable {
    services.mullvad-vpn.enable = true;
  };
}
```

**Home Module** (`modules/home/programs/mullvad.nix`):
```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.programs.mullvad;
in
{
  options.modules.programs.mullvad.enable = lib.mkEnableOption "Mullvad Browser";

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mullvad-browser ];
  };
}
```

**Usage** (confusing):
```nix
# System config
modules.services.mullvad.enable = true;

# Home config  
modules.programs.mullvad.enable = true;
```

**Problems:**
- Two files to maintain
- Two different namespaces
- Easy to enable one but forget the other
- Unclear which file to edit

### After: Unified Feature Module

**Feature Module** (`modules/features/mullvad.nix`):
```nix
{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.mullvad;
in
{
  options.modules.features.mullvad = {
    enable = mkEnableOption "Mullvad VPN and Browser";
  };

  config = mkIf cfg.enable {
    # System-level: VPN service
    services.mullvad-vpn.enable = true;

    # User-level: Browser
    home-manager.users.${userVars.username} = {
      home.packages = with pkgs; [
        mullvad-browser
      ];
    };
  };
}
```

**Usage** (clear):
```nix
# One simple enable
modules.features.mullvad.enable = true;
```

**Benefits:**
- One file, one feature
- Single namespace
- Everything together
- Clear and simple

---

## Benefits

### 1. Simplified Mental Model

**Before:**
- "Where do I configure X? System or home?"
- "Do I need both files?"
- "Which namespace do I use?"

**After:**
- "It's in `modules/features/X.nix`"
- "Enable with `modules.features.X.enable = true`"
- Done!

### 2. Reduced Code Duplication

- **1,452 lines removed** (45% reduction)
- No duplicate imports across system/home
- Single source of truth per feature

### 3. Consistent Interface

All features use the same pattern:
```nix
modules.features.<name>.enable = true;
```

No need to remember if it's:
- `modules.services.*`
- `modules.programs.*`
- `modules.wayland.*`
- `modules.hardware.*`

### 4. Easier Maintenance

- Edit one file to change a feature
- Clear ownership and responsibility
- Faster to understand and modify

### 5. Better Discoverability

```bash
# Find all features
ls modules/features/

# Find where a feature is configured
rg "modules.features" systems/
```

### 6. Atomic Feature Management

Enable/disable complete features with a single option:
```nix
# Enable Hyprland ecosystem
modules.features.hyprland.enable = true;      # Compositor + config
modules.features.hyprpanel.enable = true;     # Status bar
modules.features.hypridle.enable = true;      # Idle management

# Everything configured together!
```

---

## Related Documentation

- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed module system documentation
- **[README.md](../README.md)** - Repository overview and quick start
- **[CONTRIBUTING.md](../CONTRIBUTING.md)** - Development workflow
- **[docs/archive/prds/dendritic-lite-migration.md](archive/prds/dendritic-lite-migration.md)** - Original migration PRD

---

## Migration History

### Timeline

- **January 19, 2026** - Planning and PRD creation
- **January 20, 2026** - Phase 2 implementation begins
- **January 21, 2026** - Batch migrations (PRs #29-32)
- **January 22, 2026** - Phase 3 cleanup (PR #33) - **Migration Complete**

### Future Enhancements

The migration is complete, but potential future improvements include:

1. **Documentation**
   - ✅ Migration guide (this document)
   - ✅ Updated ARCHITECTURE.md
   - Feature module examples and patterns

2. **Tooling**
   - Script to generate new feature modules from template
   - Validation script to check module structure
   - Migration helper for future features

3. **Module Improvements**
   - Add more granular sub-options to complex features
   - Create feature "profiles" (desktop-full, server-minimal, etc.)
   - Implement feature dependency checking

---

**Last Updated**: January 22, 2026  
**Status**: Migration Complete ✅  
**Version**: 1.0
