# NixOS Configuration

Personal NixOS configuration with **unified feature modules** based on the dendritic pattern.

## 📚 Documentation

**New here?** See [DOCS.md](DOCS.md) for complete navigation.

**Architecture:**
- **[docs/DENDRITIC-MIGRATION.md](docs/DENDRITIC-MIGRATION.md)** - Unified feature modules guide ⭐ **START HERE**
- **[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)** - Detailed module system documentation
- **[FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md)** - Deploy and manage systems

**System-Specific:**
- **[systems/cortex/AI-SERVICES.md](systems/cortex/AI-SERVICES.md)** - AI/LLM infrastructure on Cortex
- **[docs/BOOTSTRAP.md](docs/BOOTSTRAP.md)** - Bootstrap new NixOS systems

**Security & Secrets:**
- **[docs/security/SECURITY.md](docs/security/SECURITY.md)** - Security configuration
- **[SECRETS.md](SECRETS.md)** - Secrets management (sops-nix + age)

## 🚀 Quick Start

**Deploy to existing system:**
```bash
./scripts/fleet.sh deploy cortex
```

**Update all systems:**
```bash
./scripts/fleet-deploy.sh update --all
```

**Local rebuild:**
```bash
sudo nixos-rebuild switch --flake .#orion
```

See [FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md) for complete deployment guide.

## 🏗️ Architecture Overview

**Unified Feature Modules** - One file per feature, containing both system and user configuration.

```
modules/
├── features/           # ⭐ PRIMARY: 30 unified feature modules
│   ├── hyprland.nix   # Wayland compositor + config
│   ├── mullvad.nix    # VPN service + browser
│   ├── git.nix        # Git + user config
│   └── ...            # All features in one place!
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
  hyprland.enable = true;
  hyprpanel.enable = true;
  
  # Development tools
  git.enable = true;
  vscode.enable = true;
  kitty.enable = true;
  
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
- 🎯 **Single source of truth**: One file per feature
- 🔧 **Consistent interface**: All use `modules.features.*`
- 📦 **Complete configuration**: System + home together
- 🧩 **Composable**: Mix and match across systems

See **[docs/DENDRITIC-MIGRATION.md](docs/DENDRITIC-MIGRATION.md)** for complete details.

## 🎯 Design Principles

1. **One Feature, One File** - All configuration for a feature in a single place
2. **Unified Namespace** - All features use `modules.features.*`
3. **Explicit Configuration** - Features never auto-enable
4. **Composability** - Mix and match features across systems
5. **Parameterization** - Configure via `userVars`/`systemVars`

See **[docs/DENDRITIC-MIGRATION.md](docs/DENDRITIC-MIGRATION.md)** for the migration story and detailed architecture.

## ➕ Adding Components

**New Feature Module:**
```bash
# 1. Create file in modules/features/
touch modules/features/myfeature.nix

# 2. Define module (see template in docs/DENDRITIC-MIGRATION.md)

# 3. Enable in system
# systems/orion/default.nix
modules.features.myfeature.enable = true;

# 4. Test and apply
nix flake check
sudo nixos-rebuild switch --flake .#orion
```

**New System:**
```bash
cp -r systems/orion systems/newsystem
# Edit variables.nix, hardware.nix, add to flake.nix
```

See **[FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md)** for detailed system setup instructions.

## � Rebuild Commands

**System (requires sudo):**
```bash
sudo nixos-rebuild switch --flake .#orion
```

**Home Manager (as NixOS module - default):**
```bash
# Rebuilt automatically with system
sudo nixos-rebuild switch --flake .#orion
```

**Home Manager (standalone):**
```bash
home-manager switch --flake .#syg
```

**Using nh (alternative):**
```bash
nh os switch    # System rebuild
nh home switch  # Home Manager rebuild
```

## � Current Systems

| System | Type | Hardware | Purpose |
|--------|------|----------|---------|
| **Orion** | Workstation | Framework 13 (AMD 7040) | Development, daily driver |
| **Cortex** | Server | RTX 5090 (32GB VRAM) | AI/LLM inference, compute |

## 🔧 Configuration Files

- **Hyprland**: `dotfiles/.config/hypr/`
- **VS Code**: `dotfiles/.config/Code/User/`
- **Git**: `dotfiles/.config/git/`
- **Wallpapers**: `wallpapers/`

## 📚 Learn More

- **[DOCS.md](DOCS.md)** - Complete documentation index
- **[FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md)** - Deployment guide
- **[systems/cortex/AI-SERVICES.md](systems/cortex/AI-SERVICES.md)** - AI infrastructure on Cortex
- **Community**: [NixOS Discourse](https://discourse.nixos.org/), [r/NixOS](https://reddit.com/r/NixOS)

---

*Configuration managed with [Nix Flakes](https://nixos.wiki/wiki/Flakes). Dotfiles symlinked by [Home Manager](https://github.com/nix-community/home-manager).*

## �🌐 LibreWolf Extensions (Reference)

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
