# Flake-Parts + Full Dendritic Migration Playbook

> **Goal**: Migrate from manual flake outputs to flake-parts while completing the full dendritic pattern for feature modules.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Phase 1: Flake-Parts Migration](#phase-1-flake-parts-migration)
- [Phase 2: Complete Dendritic Pattern](#phase-2-complete-dendritic-pattern)
- [Phase 3: Testing & Validation](#phase-3-testing--validation)
- [Phase 4: Cleanup & Documentation](#phase-4-cleanup--documentation)
- [Rollback Plan](#rollback-plan)

---

## Overview

### Current State
- ✅ Using `import-tree` for auto-imports (dendritic-lite Phase 1)
- ✅ Module structure: `modules/system/` and `modules/home/`
- ❌ Manual flake output definitions
- ❌ Split system/home configs for features (Hyprland, Mullvad, etc.)

### Target State
- ✅ Using `flake-parts` for modular flake composition
- ✅ Unified feature modules in `modules/features/`
- ✅ One file per feature with system + home config
- ✅ Consistent enable options: `modules.<feature>.enable`
- ✅ Easier to add new systems/features

### Benefits
1. **Composability**: flake-parts modules are reusable across projects
2. **Maintainability**: Feature logic in one place, not split across system/home
3. **Discoverability**: `modules/features/hyprland.nix` contains everything about Hyprland
4. **Consistency**: Standard patterns for all features
5. **Scalability**: Easy to add new systems or features

---

## Prerequisites

### Backup Current State
```bash
# Create backup branch
git checkout -b backup/pre-flake-parts-migration
git push -u origin backup/pre-flake-parts-migration

# Tag current state
git tag -a v1.0-pre-flake-parts -m "State before flake-parts migration"
git push --tags

# Return to main
git checkout main
```

### Test Current Configuration
```bash
# Verify all systems build
nix flake check --no-build

# Build each system
nixos-rebuild build --flake .#orion
nixos-rebuild build --flake .#cortex
nixos-rebuild build --flake .#nexus
nixos-rebuild build --flake .#axon
```

---

## Phase 1: Flake-Parts Migration

### Step 1.1: Add flake-parts Input

**File**: `flake.nix`

```diff
 inputs = {
+  flake-parts.url = "github:hercules-ci/flake-parts";
   nixpkgs.url = "github:nixos/nixpkgs?shallow=1&ref=nixos-unstable";
   # ... other inputs
 };
```

### Step 1.2: Restructure Flake Outputs

**Before**: Manual outputs structure
**After**: flake-parts module system

Create: `flake.nix` (new structure)

```nix
{
  description = "NixOS config flake with flake-parts";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs?shallow=1&ref=nixos-unstable";
    # ... all your existing inputs
  };

  outputs = inputs @ { flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      # Import flake modules
      imports = [
        ./flake-modules/nixos-configurations.nix
        ./flake-modules/home-configurations.nix
        ./flake-modules/deploy.nix
      ];

      # Systems to support
      systems = [ "x86_64-linux" ];

      # Per-system outputs (packages, devShells, etc.)
      perSystem = { config, self', inputs', pkgs, system, ... }: {
        # Formatter
        formatter = pkgs.nixpkgs-fmt;

        # Dev shell
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            git
            nixd
            nixpkgs-fmt
            just
          ];
        };
      };
    };
}
```

### Step 1.3: Create Flake Modules

**File**: `flake-modules/nixos-configurations.nix`

```nix
{ self, inputs, ... }: {
  flake.nixosConfigurations = {
    orion = inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs;
        inherit (inputs) self;
        hasSecrets = builtins.pathExists /home/syg/.config/nixos-secrets;
        fh = inputs.fh.packages.x86_64-linux;
      };
      modules = [
        ./systems/orion/default.nix
        inputs.home-manager.nixosModules.home-manager
        # ... other common modules
      ];
    };

    cortex = inputs.nixpkgs.lib.nixosSystem {
      # Similar structure...
    };

    nexus = inputs.nixpkgs.lib.nixosSystem {
      # Similar structure...
    };

    axon = inputs.nixpkgs.lib.nixosSystem {
      # Similar structure...
    };
  };
}
```

**File**: `flake-modules/home-configurations.nix`

```nix
{ self, inputs, ... }: {
  flake.homeConfigurations = {
    # If you have standalone home-manager configs
    # (currently you use nixosModules.home-manager)
  };
}
```

**File**: `flake-modules/deploy.nix`

```nix
{ self, inputs, ... }: {
  flake.deploy = {
    nodes = {
      orion = {
        hostname = "orion";
        profiles.system = {
          user = "root";
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos
            self.nixosConfigurations.orion;
        };
      };
      # ... other systems
    };
  };
}
```

### Step 1.4: Test Flake-Parts Migration

```bash
# Check flake structure
nix flake show

# Build a system
nixos-rebuild build --flake .#orion

# Check all systems
nix flake check --no-build

# If successful, commit
git add flake.nix flake-modules/
git commit -m "refactor: migrate to flake-parts for modular flake composition"
```

---

## Phase 2: Complete Dendritic Pattern

### Step 2.1: Create Features Directory

```bash
mkdir -p modules/features
```

### Step 2.2: Merge Feature Modules

#### Feature: Hyprland

**Create**: `modules/features/hyprland.nix`

```nix
{ config, lib, pkgs, inputs, ... }:
let
  cfg = config.modules.features.hyprland;
in
{
  options.modules.features.hyprland = {
    enable = lib.mkEnableOption "Hyprland window manager";

    terminal = lib.mkOption {
      type = lib.types.str;
      default = "kitty";
      description = "Default terminal emulator";
    };

    # ... other options
  };

  config = lib.mkIf cfg.enable {
    # System-level configuration
    programs.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    };

    security.pam.services.hyprlock = {};

    environment.systemPackages = with pkgs; [
      hyprlock
      hypridle
      hyprpicker
      # ... other system packages
    ];

    # Home-manager configuration
    home-manager.users = lib.mkMerge [
      (lib.mkIf (config.home-manager.users ? syg) {
        syg = {
          wayland.windowManager.hyprland = {
            enable = true;
            settings = {
              # Use cfg options here
              "$terminal" = cfg.terminal;
              # ... rest of hyprland config
            };
          };

          home.packages = with pkgs; [
            # User-level packages
            rofi-wayland
            waybar
            # ...
          ];

          xdg.configFile = {
            # Hyprland scripts
            "hypr/scripts/monitor-handler.sh".source =
              ./../../systems/${config.networking.hostName}/scripts/monitor-handler.sh;
            # ...
          };
        };
      })
    ];
  };
}
```

**Migration Steps**:
1. Read `modules/system/windowManagers/hyprland.nix`
2. Read `modules/home/programs/hyprland.nix`
3. Merge into `modules/features/hyprland.nix`
4. Test on Orion system
5. Once verified, delete old split files

#### Feature: Mullvad

**Create**: `modules/features/mullvad.nix`

```nix
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.features.mullvad;
in
{
  options.modules.features.mullvad = {
    enable = lib.mkEnableOption "Mullvad VPN";

    includeBrowser = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install Mullvad Browser";
    };
  };

  config = lib.mkIf cfg.enable {
    # System: VPN service
    services.mullvad-vpn.enable = true;

    # Home: Browser (optional)
    home-manager.users = lib.mkMerge [
      (lib.mkIf (config.home-manager.users ? syg && cfg.includeBrowser) {
        syg.home.packages = [ pkgs.mullvad-browser ];
      })
    ];
  };
}
```

### Step 2.3: Update System Configurations

**File**: `systems/orion/default.nix`

```diff
 modules = {
-  wayland.hyprland.enable = true;
-  services.mullvad.enable = true;
+  features = {
+    hyprland = {
+      enable = true;
+      terminal = "ghostty";
+    };
+    mullvad.enable = true;
+  };
 };
```

### Step 2.4: Update Module Imports

**File**: `modules/system.nix`

```nix
{ inputs, ... }:
{
  imports = [
    # Auto-import features
    (inputs.import-tree ./features)
    # Auto-import system-only modules
    (inputs.import-tree ./system)
  ];
}
```

### Step 2.5: Test Feature Modules

```bash
# Build system with new feature modules
nixos-rebuild build --flake .#orion

# Verify features work
# - Hyprland launches
# - Mullvad VPN connects
# - All scripts/configs present

# If successful, commit
git add modules/features/
git commit -m "refactor: merge system+home configs into unified feature modules"
```

---

## Phase 3: Testing & Validation

### Test Checklist

#### Per-System Tests
- [ ] Orion: Builds successfully
- [ ] Orion: Hyprland launches with all features
- [ ] Orion: Scripts work (monitor handling, etc.)
- [ ] Cortex: Builds successfully
- [ ] Cortex: AI services work
- [ ] Nexus: Builds successfully
- [ ] Axon: Builds successfully
- [ ] Axon: Kiosk mode works

#### Feature Tests
- [ ] Hyprland: Config files generated correctly
- [ ] Hyprland: All keybinds work
- [ ] Hyprland: Monitor scripts functional
- [ ] Mullvad: VPN service starts
- [ ] Mullvad: Browser launches (if enabled)

#### Regression Tests
```bash
# All systems should build
nix flake check --no-build

# Deploy to test VM
nixos-rebuild build-vm --flake .#orion
./result/bin/run-orion-vm

# Check flake outputs
nix flake show
```

---

## Phase 4: Cleanup & Documentation

### Step 4.1: Remove Old Split Files

```bash
# After verifying features work, remove old files
rm modules/system/windowManagers/hyprland.nix
rm modules/home/programs/hyprland.nix
rm modules/system/services/mullvad.nix
rm modules/home/programs/mullvad.nix

git add -A
git commit -m "refactor: remove old split module files after feature merge"
```

### Step 4.2: Update Documentation

**File**: `README.md` (update module structure section)

```markdown
## Module Structure

### Features (`modules/features/`)
Unified feature modules containing both system and home configuration:
- `hyprland.nix` - Hyprland window manager (system + home)
- `mullvad.nix` - Mullvad VPN service + browser
- ...

Enable in system config: `modules.features.<name>.enable = true;`

### System (`modules/system/`)
System-only modules (no home-manager component):
- `base/` - Base system configuration
- `hardware/` - Hardware-specific modules
- `services/` - System services without home config

### Home (`modules/home/`)
Home-only modules (no system component):
- `programs/` - User applications without system dependencies
```

### Step 4.3: Create Migration Guide

**File**: `docs/MIGRATION-GUIDE.md`

```markdown
# Migration Guide: Adding New Features

## Before (Old Split Pattern)
1. Create `modules/system/services/myfeature.nix`
2. Create `modules/home/programs/myfeature.nix`
3. Manually import both
4. Enable separately in system config

## After (Dendritic Pattern)
1. Create `modules/features/myfeature.nix` with:
   - System config in `config` block
   - Home config in `home-manager.users.*` block
2. Auto-imported by `import-tree`
3. Enable once: `modules.features.myfeature.enable = true;`

## Template
See `modules/features/_template.nix` for starter template.
```

---

## Rollback Plan

### If Migration Fails

```bash
# Option 1: Revert to backup branch
git checkout backup/pre-flake-parts-migration

# Option 2: Revert specific commits
git log --oneline -10
git revert <commit-hash>

# Option 3: Use git tag
git checkout v1.0-pre-flake-parts
git checkout -b rollback-temp
```

### Incremental Rollback

If a specific feature module causes issues:
```bash
# Revert just that feature
git revert <feature-commit-hash>

# Or manually disable
# In system config:
modules.features.problematic-feature.enable = false;

# Re-enable old split modules temporarily
```

---

## Post-Migration Tasks

### Step 1: Update CI/CD (if applicable)
- Update build commands to use new flake structure
- Test deploy-rs with new configurations

### Step 2: Document New Patterns
- Add examples to README
- Create feature module template
- Document option naming conventions

### Step 3: Standardize Remaining Modules
- Apply pattern to other features over time
- No rush - can be done incrementally

---

## Success Criteria

- [x] All systems build with `nix flake check`
- [x] Orion deploys and Hyprland works perfectly
- [x] Feature modules are self-contained (one file per feature)
- [x] Adding new feature = create one file, enable one option
- [x] No duplicate configs between system/home
- [x] Documentation reflects new structure

---

## Timeline Estimate

- **Phase 1** (flake-parts): 1-2 hours
- **Phase 2** (feature modules): 3-4 hours
  - Hyprland: 1-2 hours (most complex)
  - Mullvad: 30 mins (simple)
  - Others: 1-2 hours
- **Phase 3** (testing): 1-2 hours
- **Phase 4** (cleanup): 1 hour

**Total**: 6-9 hours (can be done over multiple sessions)

---

## Resources

- [flake-parts documentation](https://flake.parts/)
- [Dendritic pattern](https://github.com/mightyiam/dendritic)
- [import-tree](https://github.com/vic/import-tree)
- Your existing: `docs/archive/prds/dendritic-lite-migration.md`
