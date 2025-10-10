# NixOS Configuration

## 🏗️ Architecture Overview

This repository implements a modular, composable NixOS configuration designed for easy maintenance and multi-system/multi-user support.

## 🚀 Fleet Management

This repository includes powerful tools for managing multiple NixOS systems:

- **nixos-fleet.sh**: Universal deployment and update tool
- **deploy-rs**: Automated deployment with rollback capabilities
- **nixos-anywhere**: Initial system deployment

See [FLEET-MANAGEMENT.md](./FLEET-MANAGEMENT.md) for comprehensive guide on deploying and managing your NixOS infrastructure.

### 📁 Directory Structure

```
├── flake.nix              # Main flake entry point & system definitions
├── modules/               # Reusable configuration modules
│   ├── home/             # Home Manager modules
│   │   ├── base/         # Minimal user profile (zsh, git, btop)
│   │   ├── base-desktop/ # Desktop user profile (kitty, wallpapers)
│   │   └── programs/     # Individual program modules
│   └── system/           # NixOS system modules
│       ├── base/         # Essential NixOS foundation
│       ├── hardware/     # Audio, bluetooth, networking
│       ├── services/     # System services (syncthing, mullvad)
│       └── windowManagers/ # Desktop environments
├── systems/              # System-specific configurations
│   └── orion/           # Example system configuration
│       ├── variables.nix # System & user variables
│       ├── hardware.nix  # Hardware-specific config
│       ├── default.nix   # System configuration
│       └── homes/        # User home configurations
├── scripts/              # Utility scripts
├── dotfiles/             # Configuration files (symlinked)
└── wallpapers/           # Desktop wallpapers
```

## 🧩 How Modules Work

### System Modules (`modules/system/`)

**Base Foundation:**
- `base/default.nix` - Essential NixOS configuration for any system
- Provides: Boot loader, core packages, basic services, Nix settings

**Modular Components:**
- `hardware/audio.nix` - Audio support via PipeWire
- `hardware/networking.nix` - Network configuration
- `services/syncthing.nix` - File synchronization
- `windowManagers/hyprland.nix` - Wayland compositor

**Usage Pattern:**
```nix
# In systems/mysystem/default.nix
modules = {
  hardware.audio.enable = true;
  services.mullvad.enable = true;
  wayland.hyprland.enable = true;
};
```

### Home Manager Modules (`modules/home/`)

**Layered Profile System:**
1. **Base** (`base/default.nix`) - Essential tools for any user
2. **Desktop** (`base-desktop/default.nix`) - Adds desktop environment tools
3. **User-specific** (`systems/*/homes/user.nix`) - Personal preferences

**Program Modules:**
Each program has its own module with:
- Options for enabling/configuring the program
- Package installation
- Configuration file management
- Service setup (if needed)

**Example Module Structure:**
```nix
# modules/home/programs/myapp.nix
{ config, lib, pkgs, userVars, ... }:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.myapp;
in
{
  options.modules.programs.myapp.enable = mkEnableOption "MyApp";

  config = mkIf cfg.enable {
    home.packages = [ pkgs.myapp ];
    # Configuration files, services, etc.
  };
}
```

## 🏠 How Systems & Homes Work

### System Configuration (`systems/systemname/`)

Each system is self-contained with:

1. **`variables.nix`** - Configuration data:
   ```nix
   {
     system = { hostName = "mysystem"; };
     user = {
       username = "myuser";
       git = { username = "Git User"; email = "user@example.com"; };
       hyprland = { terminal = "kitty"; fileManager = "nemo"; };
     };
   }
   ```

2. **`default.nix`** - System configuration:
   ```nix
   {
     imports = [
       ./hardware.nix
       ../../modules/system/base    # Essential foundation
       ../../modules/system.nix     # All available modules
     ];

     modules = {
       hardware.audio.enable = true;
       services.syncthing.enable = true;
       # Mix and match as needed
     };
   }
   ```

3. **`homes/user.nix`** - User configuration:
   ```nix
   {
     imports = [ ../../../modules/home/base-desktop ];

     modules.programs = {
       hyprland.enable = true;
       vscode.enable = true;
       # User-specific applications
     };
   }
   ```

### Variable System

**Two-tier structure passed to all modules:**

- **`userVars`** - User-specific settings (`variables.user`)
  - `userVars.username` - System username
  - `userVars.git.*` - Git configuration  
  - `userVars.hyprland.*` - Desktop preferences

- **`systemVars`** - System-specific settings (`variables.system`)
  - `systemVars.hostName` - System hostname

## 🔧 How Scripts Work

### Script Integration

**Location:** `scripts/` directory
**Access:** Available in modules via `${configRoot}/scripts/`

**Key Scripts:**
- `monitor-handler.sh` - Display management for Hyprland
- `start-waybar.sh` - Launch waybar with proper environment
- `start-hyprpanel.sh` - Launch hyprpanel alternative
- `screenshot.sh` - Screenshot utilities with upload

**Usage in Modules:**
```nix
# Example: Hyprland module referencing scripts
after_sleep_cmd = "hyprctl dispatch dpms on && ${configscriptsDir}/monitor-handler.sh --fast --bar=hyprpanel";
```

**Environment Setup:**
Scripts have access to `$NIXOS_CONFIG_DIR` pointing to the configuration root.

## 🎯 Design Principles

1. **Composition over Inheritance** - Mix and match modules as needed
2. **Parameterization** - All modules accept configuration via `userVars`/`systemVars`
3. **Reusability** - Modules work across different systems and users
4. **Self-Documentation** - Clear structure makes patterns obvious
5. **Minimal Abstraction** - Only add complexity when it provides clear value

## ➕ Adding New Components

### Adding a New System

1. **Copy existing system:**
   ```bash
   cp -r systems/orion systems/newsystem
   ```

2. **Update variables:**
   ```nix
   # systems/newsystem/variables.nix
   { system.hostName = "newsystem"; user.username = "newuser"; }
   ```

3. **Generate hardware config:**
   ```bash
   nixos-generate-config --dir systems/newsystem
   ```

4. **Add to flake.nix:**
   ```nix
   nixosConfigurations.newsystem = nixpkgs.lib.nixosSystem { ... };
   ```

### Adding a New User

1. **Update variables:** Add user to `systems/systemname/variables.nix`
2. **Create home config:** `systems/systemname/homes/newuser.nix`
3. **Choose base layer:** Import appropriate base (minimal/desktop)
4. **Add programs:** Enable desired applications

### Adding a New Module

1. **Create module file** in appropriate directory
2. **Follow module pattern** with options and config
3. **Add to imports** (auto-imported for system modules)
4. **Use in systems** by enabling the module

## 🔧 Namespace Strategy

This configuration uses a custom namespace for all user-defined modules to avoid collisions with upstream Home Manager modules and keep things modular and future-proof.

- **Custom modules:** Options and config are defined under `modules.programs.<name>` (e.g., `modules.programs.protonmail-bridge`).
- **Upstream modules:** Configuration uses the standard `programs.<name>` namespace (e.g., `programs.kitty`).
- **Why:** This avoids any risk of collision if Home Manager adds support for a program you already manage, and keeps your config organized.
- **If a collision occurs:** Refactor your custom module to a new namespace or migrate to the upstream module as needed.

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
└── wallpapers/          # Desktop wallpapers
```

## 🚀 Quick Start

### Rebuild System (NixOS)
```bash
# Using nh (recommended)
nh os switch

# Or using the standard command (requires sudo)
sudo nixos-rebuild switch --flake .
```

### Rebuild Home Manager

#### As NixOS Module (Default)
This is handled automatically when you rebuild the system with `nh os switch` or `nixos-rebuild switch`.

#### As Standalone Home Manager
```bash
# Using nh (recommended)
nh home switch

# Or using the standard command (no sudo required)
home-manager switch --flake .#syg

# First time setup on a new machine (if home-manager is not yet installed)
nix run home-manager -- switch --flake .#syg
```

## 🔄 Dual-Mode Configuration

This configuration supports two modes of operation:

### 1. NixOS Module Mode (Default)
- Home Manager runs as a NixOS module
- Configuration: `home/syg.nix`
- Requires `sudo` for rebuilds
- System and home configuration rebuilt together

### 2. Standalone Home Manager Mode
- Home Manager runs independently 
- Configuration: `home-standalone.nix`
- No `sudo` required for home rebuilds
- Faster iteration for home-only changes
- Works on non-NixOS systems

### When to Use Each Mode

**Use NixOS Module Mode when:**
- Making system-wide changes
- You want everything rebuilt together
- First-time setup

**Use Standalone Mode when:**
- Testing home configuration changes
- You don't have sudo access
- Working on a non-NixOS system
- Faster development iteration

## 🌐 LibreWolf Extensions

### Adding Extensions

#### Method 1: Enable Existing Extensions
Some extensions are already configured but commented out. To enable them:

1. Edit `modules/home/programs/librewolf.nix`
2. Uncomment the desired extension by removing the `#` symbol
3. Rebuild with `home-manager switch --flake .`

#### Method 2: Add New Extensions

1. **Find the extension** on [addons.mozilla.org](https://addons.mozilla.org)
2. **Get the short ID** from the URL:
   ```
   https://addons.mozilla.org/en-US/firefox/addon/SHORT_ID/
   ```
3. **Get the UUID** (extension ID) using one of these methods:
   - **Method A**: Download the XPI file, unzip it, and run:
     ```bash
     jq .browser_specific_settings.gecko.id manifest.json
     ```
   - **Method B**: Install manually in LibreWolf → `about:addons` → extension details → copy ID

4. **Add to configuration**:
   ```nix
   (extension "short-id" "uuid@example.com")
   ```

5. **Where to get the required information:**

   - **Short ID:**
     - This is the last part of the add-on’s URL on [addons.mozilla.org](https://addons.mozilla.org).
     - Example: For `https://addons.mozilla.org/en-US/firefox/addon/ublock-origin/`, the short ID is `ublock-origin`.

   - **UUID (Extension ID):**
     - **Method 1:** Download the `.xpi` file from the add-on page, unzip it, and look for the `id` in `manifest.json`:
       ```bash
       unzip addon.xpi -d addon
       jq .browser_specific_settings.gecko.id addon/manifest.json
       ```
     - **Method 2:** Install the extension in LibreWolf, go to `about:support`, and look for the Extension ID under Extensions.

   - **Example entry:**
     ```nix
     (extension "ublock-origin" "uBlock0@raymondhill.net")
     ```

### Popular Extension UUIDs

| Extension | Short ID | UUID |
|-----------|----------|------|
| uBlock Origin | `ublock-origin` | `uBlock0@raymondhill.net` |
| Bitwarden | `bitwarden-password-manager` | `{446900e4-71c2-419f-a6a7-df9c091e268b}` |
| Privacy Badger | `privacy-badger17` | `jid1-MnnxcxisBPnSXQ@jetpack` |
| DuckDuckGo Privacy Essentials | `duckduckgo-for-firefox` | `jid1-ZAdIEUB7XOzOJw@jetpack` |
| Decentraleyes | `decentraleyes` | `jid1-BoFifL9Vbdl2zQ@jetpack` |
| ClearURLs | `clearurls` | `{74145f27-f039-47ce-a470-a662b129930a}` |
| Dark Reader | `darkreader` | `addon@darkreader.org` |
| Tree Style Tab | `tree-style-tab` | `treestyletab@piro.sakura.ne.jp` |
| Violentmonkey | `violentmonkey` | `{aecec67f-0d10-4fa7-b7c7-609a2db280cf}` |
| Multi-Account Containers | `multi-account-containers` | `@testpilot-containers` |

## 🔧 Other Configurations

### Hyprland
- Configuration: `dotfiles/.config/hypr/`
- Wallpapers: `wallpapers/`
- Scripts: `scripts/`

### Development
- VS Code settings: `dotfiles/.config/Code/User/settings.json`
- Git configuration: `dotfiles/.config/git/`

## 📋 Notes

- Dotfiles are managed using Home Manager with live-updating symlinks
- Monitor configuration is stored in `monitors.json`
- Additional notes in `notes.txt`
