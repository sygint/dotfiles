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

### Development Environments (devenv)

This configuration includes support for [devenv](https://devenv.sh/), a fast and declarative development environment manager.

#### Quick Start with devenv

1. **Navigate to a project directory**:
   ```bash
   mkdir my-project && cd my-project
   ```

2. **Initialize devenv**:
   ```bash
   devenv init
   ```

3. **Edit `devenv.nix`** to configure your development environment

4. **Create `.envrc`**:
   ```bash
   echo "use devenv" > .envrc
   direnv allow
   ```

#### Example Development Environments

The configuration includes example devenv setups in the `shells/` directory:

- **Node.js**: `shells/node-devenv/` - Complete Node.js development environment with TypeScript, pnpm, and pre-commit hooks
- **Python**: `shells/python-devenv/` - Python development environment with virtual env, ruff, black, and testing tools

#### Using the Examples

```bash
# Copy an example to your project
cp -r ~/.config/nixos/shells/node-devenv/* ./
# or
cp -r ~/.config/nixos/shells/python-devenv/* ./

# Allow direnv
direnv allow

# Your development environment is now active!
```

#### devenv Features Available

- **Language support**: Python, Node.js, Go, Rust, and more
- **Services**: PostgreSQL, Redis, databases, etc.
- **Pre-commit hooks**: Automatic linting and formatting
- **Scripts**: Custom development commands
- **Process management**: Run multiple services
- **Testing**: Automated environment testing

#### Comparison with Traditional Flakes

| Feature | Traditional `flake.nix` | devenv |
|---------|-------------------------|--------|
| **Learning curve** | Steep | Gentle |
| **Configuration** | Complex | Declarative & simple |
| **Services** | Manual setup | Built-in service management |
| **Pre-commit** | Manual integration | Automatic setup |
| **Processes** | External tools needed | Built-in process manager |
| **Speed** | Fast | Very fast with caching |

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
