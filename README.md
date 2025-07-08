# NixOS Configuration

This repository contains my personal NixOS and Home Manager configuration using Nix flakes.

## 📁 Structure

```
├── flake.nix              # Main flake configuration
├── flake.lock            # Flake lock file
├── variables.nix         # Global variables
├── home/                 # User-specific configurations
├── modules/              # Modular configurations
│   ├── home/            # Home Manager modules
│   └── nixos/           # NixOS system modules
├── systems/             # System configurations
├── dotfiles/            # Dotfiles managed by Home Manager
├── scripts/             # Utility scripts
├── wallpapers/          # Desktop wallpapers
└── docs/                # Documentation
```

## 🚀 Quick Start

```bash
# Rebuild system
nh os switch

# Rebuild home configuration
nh home switch
```

## 📚 Documentation

- **[Usage Guide](docs/usage.md)** - How to rebuild, dual-mode configuration
- **[Development Environments](docs/development.md)** - DevEnv templates and examples
- **[LibreWolf Configuration](docs/librewolf.md)** - Browser extensions and setup

## ✨ Features

- **Modular configuration** with Home Manager
- **Live-updating dotfiles** via symlinks  
- **Development environments** with devenv support
- **Hyprland window manager** with custom scripts
- **Dual-mode operation** (NixOS module or standalone Home Manager)

## 🔧 Key Components

- **Desktop**: Hyprland + HyprPanel + various tools
- **Terminal**: Zsh with Starship prompt and plugins
- **Editor**: VS Code with Nix-managed settings
- **Browser**: LibreWolf with privacy extensions
- **Development**: DevEnv for project environments
