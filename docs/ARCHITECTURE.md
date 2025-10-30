# NixOS Configuration Architecture

**Detailed Module System Documentation**

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Design Principles](#design-principles)
3. [Module Organization](#module-organization)
4. [System Modules](#system-modules)
5. [Home Manager Modules](#home-manager-modules)
6. [Variable System](#variable-system)
7. [Creating New Modules](#creating-new-modules)
8. [Best Practices](#best-practices)

---

## Overview

This configuration uses a modular architecture where functionality is broken into small, reusable, and composable modules. Each module is self-contained and can be enabled/disabled independently.

### Key Benefits

- **Reusability**: Modules work across different systems
- **Maintainability**: Changes isolated to specific modules
- **Clarity**: Each module has a single, clear purpose
- **Flexibility**: Mix and match features per system
- **Type Safety**: Options provide validation and documentation

---

## Design Principles

### 1. Namespacing
Custom modules use `modules.programs.*` to avoid conflicts with upstream NixOS/Home Manager options.

**Example:**
```nix
# Custom module
modules.programs.hyprland.enable = true;

# vs upstream
programs.hyprland.enable = true;
```

### 2. Composability
Modules can be mixed and matched without dependencies (where possible).

```nix
# System A: Minimal
modules.programs.base.enable = true;

# System B: Full desktop
modules.programs = {
  base.enable = true;
  base-desktop.enable = true;
  hyprland.enable = true;
  vscode.enable = true;
};
```

### 3. Parameterization
All modules accept `userVars` and `systemVars` for dynamic configuration.

```nix
# Module receives variables
{ config, pkgs, userVars, systemVars, ... }:
{
  # Use variables in configuration
  programs.git.userName = userVars.git.username;
}
```

### 4. Optional by Default
Every module can be enabled/disabled via options.

```nix
options.modules.programs.mymodule.enable = mkEnableOption "My Module";

config = mkIf cfg.enable {
  # Module configuration only applies if enabled
};
```

### 5. Self-Contained
Each module manages its own packages, configurations, and services.

```nix
# Module includes everything it needs
config = mkIf cfg.enable {
  home.packages = [ pkgs.neovim ];  # Packages
  programs.neovim.enable = true;     # Programs
  home.file.".config/nvim".source = ./nvim;  # Config files
};
```

---

## Module Organization

```
modules/
├── system.nix           # System module aggregator
├── home.nix             # Home module aggregator
├── system/              # NixOS system-level modules
│   ├── base/            # Essential system foundation
│   │   └── default.nix  # Boot, nix settings, core packages
│   ├── hardware/        # Hardware support
│   │   ├── audio.nix
│   │   ├── bluetooth.nix
│   │   ├── networking.nix
│   │   └── printing.nix
│   ├── services/        # System services
│   │   ├── ssh.nix
│   │   ├── mullvad.nix
│   │   └── syncthing.nix
│   ├── windowManagers/  # Desktop environments
│   │   ├── hyprland.nix
│   │   └── i3.nix
│   ├── displayServers/  # X11, Wayland
│   │   └── wayland.nix
│   ├── programs/        # System-wide programs
│   │   └── gaming.nix
│   └── locale.nix       # Localization
└── home/                # Home Manager user-level modules
    ├── base/            # Minimal CLI user profile
    │   └── default.nix  # Shell, git, basic tools
    ├── base-desktop/    # Desktop user profile
    │   └── default.nix  # Terminal, file manager, GUI apps
    └── programs/        # Individual program modules
        ├── hyprland.nix
        ├── vscode.nix
        ├── librewolf.nix
        ├── brave.nix
        └── ... (30+ modules)
```

### Aggregator Files

**`modules/system.nix`**: Imports all system modules
```nix
{
  imports = [
    ./system/base
    ./system/hardware/audio.nix
    ./system/hardware/bluetooth.nix
    # ... all system modules
  ];
}
```

**`modules/home.nix`**: Imports all home modules
```nix
{
  imports = [
    ./home/base
    ./home/base-desktop
    ./home/programs/hyprland.nix
    # ... all home modules
  ];
}
```

---

## System Modules

System modules configure NixOS system-level settings. They run as root and affect the entire system.

### Base Foundation (`modules/system/base/`)

The core system configuration applied to all machines.

**Responsibilities:**
- Boot loader configuration (systemd-boot, GRUB)
- Nix daemon settings (flakes, garbage collection)
- Core system packages (vim, wget, curl)
- Essential services (systemd units)
- User account creation

**Key Configuration:**
```nix
modules.system.base.enable = true;  # Applied to all systems

# Includes:
# - Nix settings (experimental features, auto-optimise)
# - Boot loader (UEFI support)
# - System packages (essential CLI tools)
# - User creation from variables
```

### Hardware Modules (`modules/system/hardware/`)

Hardware support modules for audio, Bluetooth, networking, etc.

#### Audio (`audio.nix`)
```nix
modules.hardware.audio.enable = true;

# Provides:
# - PipeWire audio server
# - ALSA/PulseAudio compatibility
# - Real-time audio scheduling
# - Bluetooth audio support (if enabled)
```

#### Bluetooth (`bluetooth.nix`)
```nix
modules.hardware.bluetooth.enable = true;

# Provides:
# - Bluez Bluetooth stack
# - Controller power management
# - Experimental features (battery percentage, etc.)
```

#### Networking (`networking.nix`)
```nix
modules.hardware.networking.enable = true;

# Provides:
# - NetworkManager
# - WiFi support
# - Firewall configuration
# - Network optimization (TCP fastopen, BBR)
```

#### Printing (`printing.nix`)
```nix
modules.hardware.printing.enable = true;

# Provides:
# - CUPS printing system
# - Common printer drivers
# - Network printer discovery
```

### Service Modules (`modules/system/services/`)

System services like SSH, VPN, synchronization.

#### SSH (`ssh.nix`)
```nix
modules.services.ssh = {
  enable = true;
  hardening = true;  # Apply security hardening
};

# Provides:
# - OpenSSH server
# - Key-based authentication only
# - Security hardening (optional)
# - Rate limiting, timeouts
```

#### Mullvad VPN (`mullvad.nix`)
```nix
modules.services.mullvad.enable = true;

# Provides:
# - Mullvad VPN client
# - WireGuard/OpenVPN support
# - Kill switch functionality
```

#### Syncthing (`syncthing.nix`)
```nix
modules.services.syncthing = {
  enable = true;
  user = "syg";
};

# Provides:
# - Syncthing file synchronization
# - Per-user configuration
# - Automatic startup
```

### Window Manager Modules (`modules/system/windowManagers/`)

Desktop environment and compositor configuration.

#### Hyprland (`hyprland.nix`)
```nix
modules.windowManagers.hyprland.enable = true;

# Provides:
# - Hyprland Wayland compositor
# - XWayland for legacy apps
# - Portal integrations (file picker, screen sharing)
# - Display manager configuration
```

---

## Home Manager Modules

Home Manager modules configure user-level settings. They run as the user and affect only that user's environment.

### Base Layer (`modules/home/base/`)

Minimal CLI user profile for all systems.

**Includes:**
- Zsh shell with configuration
- Git with user credentials
- Core CLI tools (btop, htop, eza, bat)
- Basic utilities (ripgrep, fd, fzf)
- SSH client configuration

**Usage:**
```nix
modules.programs.base.enable = true;  # On all systems
```

### Desktop Layer (`modules/home/base-desktop/`)

Desktop user profile building on base layer.

**Includes:**
- Kitty terminal emulator
- File manager (Nemo/Thunar)
- Desktop utilities (clipboard, screenshots)
- Wallpaper management
- Font configuration
- GTK/Qt theming

**Usage:**
```nix
modules.programs = {
  base.enable = true;          # CLI foundation
  base-desktop.enable = true;  # Add GUI tools
};
```

### Program Modules (`modules/home/programs/`)

Individual application configurations.

#### Hyprland (`hyprland.nix`)
```nix
modules.programs.hyprland = {
  enable = true;
  packages.enable = true;  # Waybar, rofi, etc.
  defaults = {
    terminal = "kitty";
    fileManager = "nemo";
    browser = "librewolf";
  };
};

# Provides:
# - Hyprland compositor config
# - Keybindings and window rules
# - Status bar (Hyprpanel/Waybar)
# - Application launcher (rofi)
# - Workspace management
```

#### VS Code (`vscode.nix`)
```nix
modules.programs.vscode = {
  enable = true;
  extensions = true;  # Install recommended extensions
};

# Provides:
# - VS Code with NixOS integration
# - Extensions (Nix IDE, GitLens, etc.)
# - Settings and keybindings
# - Theme configuration
```

#### Browsers (`librewolf.nix`, `brave.nix`)
```nix
modules.programs.librewolf.enable = true;
modules.programs.brave.enable = true;

# Provides:
# - Browser installation
# - Privacy settings
# - Hardware acceleration (Brave)
# - Extension management (planned)
```

---

## Variable System

Configuration is parameterized through a two-tier variable system defined in each system's `variables.nix`.

### Structure

**`systems/<hostname>/variables.nix`:**
```nix
{
  system = {
    hostName = "orion";
    timeZone = "America/New_York";
    locale = "en_US.UTF-8";
    # System-specific settings
  };
  
  user = {
    username = "syg";
    fullName = "Your Name";
    email = "your@email.com";
    
    git = {
      username = "Your Name";
      email = "your@email.com";
      signingKey = "ABCD1234";
    };
    
    hyprland = {
      terminal = "kitty";
      fileManager = "nemo";
      browser = "librewolf";
      monitor = "eDP-1";
    };
    
    # User preferences
  };
}
```

### Usage in Modules

**System Module:**
```nix
{ config, pkgs, systemVars, userVars, ... }:
{
  networking.hostName = systemVars.hostName;
  time.timeZone = systemVars.timeZone;
  
  users.users.${userVars.username} = {
    isNormalUser = true;
    description = userVars.fullName;
    extraGroups = [ "wheel" "networkmanager" ];
  };
}
```

**Home Module:**
```nix
{ config, pkgs, userVars, ... }:
{
  programs.git = {
    enable = true;
    userName = userVars.git.username;
    userEmail = userVars.git.email;
    signing = {
      key = userVars.git.signingKey;
      signByDefault = true;
    };
  };
  
  wayland.windowManager.hyprland = {
    settings = {
      "$terminal" = userVars.hyprland.terminal;
      "$fileManager" = userVars.hyprland.fileManager;
      "$browser" = userVars.hyprland.browser;
    };
  };
}
```

### Variable Flow

```
systems/orion/variables.nix
         ↓
systems/orion/default.nix (imports variables)
         ↓
flake.nix (passes as specialArgs)
         ↓
modules receive as function parameters
         ↓
Used throughout configuration
```

---

## Creating New Modules

### System Module Template

**`modules/system/services/myservice.nix`:**
```nix
{ config, lib, pkgs, systemVars, userVars, ... }:

let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.modules.services.myservice;
in
{
  options.modules.services.myservice = {
    enable = mkEnableOption "My Service";
    
    port = mkOption {
      type = types.port;
      default = 8080;
      description = "Port to listen on";
    };
  };

  config = mkIf cfg.enable {
    # Service configuration
    systemd.services.myservice = {
      enable = true;
      description = "My Service";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        ExecStart = "${pkgs.mypackage}/bin/myservice --port ${toString cfg.port}";
        Restart = "always";
      };
    };
    
    # Firewall
    networking.firewall.allowedTCPPorts = [ cfg.port ];
    
    # Packages
    environment.systemPackages = [ pkgs.mypackage ];
  };
}
```

### Home Module Template

**`modules/home/programs/myprogram.nix`:**
```nix
{ config, lib, pkgs, userVars, ... }:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.myprogram;
in
{
  options.modules.programs.myprogram = {
    enable = mkEnableOption "My Program";
  };

  config = mkIf cfg.enable {
    # Install package
    home.packages = [ pkgs.myprogram ];
    
    # Configuration file
    home.file.".config/myprogram/config.toml".text = ''
      username = "${userVars.username}"
      email = "${userVars.email}"
    '';
    
    # XDG configuration
    xdg.configFile."myprogram/settings.json".source = ./myprogram-settings.json;
  };
}
```

### Steps to Add a Module

1. **Create module file** in appropriate directory
2. **Define options** with `mkEnableOption` and `mkOption`
3. **Implement config** with `mkIf cfg.enable`
4. **Import in aggregator** (`modules/system.nix` or `modules/home.nix`)
5. **Enable in system config** (`systems/<hostname>/default.nix` or `homes/<user>.nix`)
6. **Test** with `nix flake check` and rebuild

---

## Best Practices

### Module Design

1. **Single Responsibility**: Each module does one thing well
2. **No Implicit Dependencies**: Declare dependencies explicitly
3. **Sensible Defaults**: Provide good defaults, allow overrides
4. **Documentation**: Document options and their purpose
5. **Conditional Logic**: Use `mkIf` to ensure clean evaluation

### Configuration

1. **Use Variables**: Avoid hardcoding values
2. **Enable Explicitly**: Don't auto-enable modules
3. **Layer Modules**: Base → Desktop → Specialized
4. **Test Incrementally**: Enable one module at a time
5. **Version Control**: Commit after each working change

### File Organization

1. **Group by Function**: Hardware, services, programs
2. **Consistent Naming**: Use lowercase, descriptive names
3. **Separate Concerns**: System vs user configuration
4. **Reusable Configs**: Extract common patterns to modules
5. **Document Structure**: README in module directories

### Common Patterns

**Conditional Features:**
```nix
options.modules.programs.myprogram = {
  enable = mkEnableOption "My Program";
  extraFeatures = mkEnableOption "Extra Features";
};

config = mkIf cfg.enable {
  # Base configuration
  home.packages = [ pkgs.myprogram ];
  
  # Optional features
  home.packages = mkIf cfg.extraFeatures [
    pkgs.myprogram-plugins
  ];
};
```

**List Options:**
```nix
options.modules.programs.myprogram = {
  enable = mkEnableOption "My Program";
  plugins = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "List of plugins to enable";
  };
};

config = mkIf cfg.enable {
  home.packages = with pkgs; [
    myprogram
  ] ++ map (p: pkgs."myprogram-${p}") cfg.plugins;
};
```

**Attribute Set Options:**
```nix
options.modules.programs.myprogram = {
  enable = mkEnableOption "My Program";
  settings = mkOption {
    type = types.attrs;
    default = {};
    description = "Configuration settings";
  };
};

config = mkIf cfg.enable {
  home.file.".config/myprogram/config.json".text = 
    builtins.toJSON cfg.settings;
};
```

---

## Related Documentation

- [PROJECT-OVERVIEW.md](PROJECT-OVERVIEW.md) - High-level project documentation
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Development workflow
- [FLEET-MANAGEMENT.md](../FLEET-MANAGEMENT.md) - Multi-system deployment
- [SECRETS.md](../SECRETS.md) - Secrets management guide

---

**Last Updated**: October 29, 2025
