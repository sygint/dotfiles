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
├── dotfiles/            # Dotfiles managed by chezmoi
├── scripts/             # Utility scripts
└── wallpapers/          # Desktop wallpapers
```

## 🚀 Quick Start

### Rebuild System
```bash
sudo nixos-rebuild switch --flake .
```

### Rebuild Home Manager
```bash
home-manager switch --flake .
```

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
- Configuration: `dotfiles/dot_config/hypr/`
- Wallpapers: `wallpapers/`
- Scripts: `scripts/`

### Development
- VS Code settings: `dotfiles/dot_config/Code/User/settings.json`
- Git configuration: `dotfiles/dot_config/git/`

## 📋 Notes

- Dotfiles are managed using chezmoi
- Monitor configuration is stored in `monitors.json`
- Additional notes in `notes.txt`
