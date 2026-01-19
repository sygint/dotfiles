# Flake-Parts + Dendritic Quick Reference

## Quick Commands

```bash
# Check flake structure
nix flake show

# Build a system
nixos-rebuild build --flake .#orion

# Test in VM
nixos-rebuild build-vm --flake .#orion
./result/bin/run-orion-vm

# Validate all systems
nix flake check --no-build

# Format flake
nix fmt
```

## Adding a New Feature Module

### 1. Create Feature File
```bash
cp modules/features/_template.nix modules/features/myfeature.nix
```

### 2. Edit Feature Module
```nix
# modules/features/myfeature.nix
{ config, lib, pkgs, ... }:
let cfg = config.modules.features.myfeature;
in {
  options.modules.features.myfeature = {
    enable = lib.mkEnableOption "My feature";
  };

  config = lib.mkIf cfg.enable {
    # System config
    services.myfeature.enable = true;

    # Home config
    home-manager.users.syg = {
      programs.myfeature.enable = true;
    };
  };
}
```

### 3. Enable in System Config
```nix
# systems/orion/default.nix
{
  modules.features.myfeature.enable = true;
}
```

### 4. Build & Test
```bash
nixos-rebuild build --flake .#orion
```

That's it! No manual imports needed - `import-tree` handles it.

## Common Patterns

### System Service + User Config
```nix
config = lib.mkIf cfg.enable {
  # System service
  services.myapp.enable = true;

  # User config
  home-manager.users.syg = {
    programs.myapp = {
      enable = true;
      settings = cfg.userSettings;
    };
  };
};
```

### Conditional Home Config
```nix
home-manager.users = lib.mkMerge [
  (lib.mkIf (config.home-manager.users ? syg) {
    syg = { /* config */ };
  })
  (lib.mkIf (config.home-manager.users ? kiosk) {
    kiosk = { /* config */ };
  })
];
```

### System-Only (No Home Config)
```nix
# modules/system/services/myservice.nix
config = lib.mkIf cfg.enable {
  services.myservice = {
    enable = true;
    # ... pure system config
  };
};
```

### Home-Only (No System Config)
```nix
# modules/home/programs/myapp.nix
config = lib.mkIf cfg.enable {
  home.packages = [ pkgs.myapp ];
  programs.myapp.enable = true;
};
```

## Option Naming Convention

```nix
modules.features.<feature>.enable          # Unified feature modules
modules.system.<subsystem>.<feature>.enable  # System-only
modules.home.<category>.<feature>.enable     # Home-only
```

Examples:
- `modules.features.hyprland.enable`
- `modules.system.hardware.audio.enable`
- `modules.home.programs.firefox.enable`

## Flake Structure

```
.
├── flake.nix                      # Main flake (flake-parts entry)
├── flake-modules/                 # Flake-parts modules
│   ├── nixos-configurations.nix   # NixOS system configs
│   ├── home-configurations.nix    # Standalone home configs
│   └── deploy.nix                 # deploy-rs config
├── modules/
│   ├── features/                  # Unified feature modules
│   │   ├── _template.nix          # Template (ignored by import)
│   │   ├── hyprland.nix          # System + home
│   │   └── mullvad.nix           # System + home
│   ├── system/                    # System-only modules
│   │   ├── base/
│   │   ├── hardware/
│   │   └── services/
│   ├── home/                      # Home-only modules
│   │   └── programs/
│   ├── system.nix                 # Auto-import system modules
│   └── home.nix                   # Auto-import home modules
└── systems/
    ├── orion/
    ├── cortex/
    ├── nexus/
    └── axon/
```

## Migration Checklist

- [ ] Backup: Create `backup/pre-flake-parts-migration` branch
- [ ] Phase 1: Add flake-parts to inputs
- [ ] Phase 1: Create flake-modules/ directory
- [ ] Phase 1: Restructure flake.nix outputs
- [ ] Phase 1: Test: `nix flake check --no-build`
- [ ] Phase 2: Create modules/features/ directory
- [ ] Phase 2: Merge Hyprland (system + home)
- [ ] Phase 2: Merge Mullvad (system + home)
- [ ] Phase 2: Update system configs to use new options
- [ ] Phase 2: Test: `nixos-rebuild build --flake .#orion`
- [ ] Phase 3: Test all systems build
- [ ] Phase 3: Test Orion deploys and works
- [ ] Phase 4: Remove old split files
- [ ] Phase 4: Update documentation
- [ ] Phase 4: Commit and push

## Troubleshooting

### Feature module not being imported
- Check filename doesn't start with `_` (those are ignored)
- Verify `modules/system.nix` has `import-tree` for features
- Run `nix flake show` to see available options

### Home-manager config not applying
- Ensure user exists: `lib.mkIf (config.home-manager.users ? username)`
- Check home-manager is imported as NixOS module
- Verify option path: `home-manager.users.<username>.<option>`

### System doesn't build after migration
- Check flake-parts syntax: `nix flake check`
- Verify all imports in flake-modules/
- Compare with backup branch

### Deploy-rs fails
- Update node paths in `flake-modules/deploy.nix`
- Ensure SSH keys are set up
- Check hostname resolution

## Resources

- Full playbook: `docs/FLAKE-PARTS-DENDRITIC-PLAYBOOK.md`
- Original PRD: `docs/archive/prds/dendritic-lite-migration.md`
- Template: `modules/features/_template.nix`
- flake-parts: https://flake.parts/
- Dendritic: https://github.com/mightyiam/dendritic
