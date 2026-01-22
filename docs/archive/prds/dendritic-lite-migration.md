# PRD: Dendritic-Lite Module Architecture

## Overview

Adopt "one file = one feature" organization inspired by the [Dendritic pattern](https://github.com/mightyiam/dendritic), without the full flake-parts migration. This simplifies understanding, reduces file hunting, and makes per-machine targeting cleaner.

## Goals

1. **Feature-centric organization** - Everything about a feature lives in one file
2. **Auto-imports** - No more manually maintaining import lists
3. **Cleaner per-machine targeting** - Already have `modules.X.enable`, standardize it

## Non-Goals

- Full dendritic/flake-parts migration (too much churn for current needs)
- nix-darwin or nix-on-droid support (Linux-only for now)
- Changing existing option names (maintain backwards compatibility)

---

## Implementation Checklist

### Phase 1: Auto-Imports with import-tree

- [ ] Add `import-tree` to flake inputs
- [ ] Update `modules/system.nix` to use auto-import instead of manual list
- [ ] Update `modules/home.nix` to use auto-import instead of manual list
- [ ] Test: Add a new module file, verify it's picked up automatically
- [ ] Document: Add comment explaining auto-import behavior

### Phase 2: Merge Feature Files (High-Value Candidates)

These currently have split system/home configs that belong together:

| Feature | System File | Home File | Merge Priority |
|---------|-------------|-----------|----------------|
| **Mullvad** | `system/services/mullvad.nix` | `home/programs/mullvad.nix` | High - trivial merge |
| **Hyprland** | `system/windowManagers/hyprland.nix` | `home/programs/hyprland.nix` | High - related configs |
| **Hyprpanel** | (none) | `home/programs/hyprpanel.nix` | Medium - add system deps |
| **Waybar** | (none) | `home/programs/waybar.nix` | Medium - add system deps |

#### Merge Tasks

- [ ] Create `modules/features/` directory for merged feature modules
- [ ] **Mullvad**: Merge into `modules/features/mullvad.nix`
  - System: `services.mullvad-vpn.enable`
  - Home: `home.packages = [ mullvad-browser ]`
  - Option: `modules.features.mullvad.enable`
- [ ] **Hyprland**: Merge into `modules/features/hyprland.nix`
  - System: PAM service, hyprlock, system packages
  - Home: Config files, dotfiles, user packages
  - Preserve existing options structure
- [ ] Update system configs to use new feature paths
- [ ] Remove old split files after verification

### Phase 3: Standardize Enable Options

Current option paths are inconsistent:
- `modules.services.syncthing.enable`
- `modules.wayland.hyprland.enable`  
- `modules.programs.vscode.enable`

Proposed standardization (backwards-compatible aliases):

- [ ] Define standard option namespace: `modules.<feature>.enable`
- [ ] Add deprecation warnings for old paths (optional)
- [ ] Document option naming convention

### Phase 4: New Structure Layout

```
modules/
├── _lib/                    # Shared utilities (ignored by auto-import)
│   └── imports.nix          # Optional: custom import helpers
├── features/                # Merged system+home feature modules
│   ├── hyprland.nix         # WM + home config + packages
│   ├── mullvad.nix          # Service + browser
│   ├── syncthing.nix        # Already good, move here
│   └── containerization.nix # Already good, move here
├── system/                  # System-only modules (no home equivalent)
│   ├── base/
│   ├── hardware/
│   └── services/            # Services without home component
└── home/                    # Home-only modules (no system equivalent)
    └── programs/            # User apps without system config
```

---

## File Analysis

### Already Well-Structured (Keep As-Is)
These are already self-contained features with proper enable options:

| File | Option Path | Status |
|------|-------------|--------|
| `system/services/syncthing.nix` | `modules.services.syncthing.enable` | ✅ Good |
| `system/services/containerization.nix` | `modules.services.containerization.enable` | ✅ Good |
| `system/services/virtualization.nix` | `modules.services.virtualization.enable` | ✅ Good |
| `home/programs/vscode.nix` | `modules.programs.vscode.enable` | ✅ Good |
| `home/programs/git.nix` | `modules.programs.git.enable` | ✅ Good |

### Home-Only (No System Component Needed)
These are pure home-manager configs, fine in `modules/home/`:

- `home/programs/brave.nix`
- `home/programs/firefox.nix`
- `home/programs/kitty.nix`
- `home/programs/zsh.nix`
- `home/programs/btop.nix`

### Merge Candidates (System + Home)
These have related configs split across files:

| Feature | Why Merge |
|---------|-----------|
| Mullvad | Service + browser belong together |
| Hyprland | WM system config + home dotfiles |

---

## Technical Details

### import-tree Usage

```nix
# flake.nix inputs
import-tree.url = "github:vic/import-tree";

# modules/system.nix (new)
{ inputs, ... }:
{
  imports = (inputs.import-tree.withLib inputs.nixpkgs.lib).leafs ./system;
}
```

### Feature Module Template

```nix
# modules/features/example.nix
{ config, lib, pkgs, ... }:
let
  cfg = config.modules.example;
in
{
  options.modules.example = {
    enable = lib.mkEnableOption "Example feature";
    # feature-specific options...
  };

  config = lib.mkIf cfg.enable {
    # System-level config
    services.example.enable = true;
    
    # Home-manager config (when using HM as NixOS module)
    home-manager.users.syg = {
      # User-level config for this feature
    };
  };
}
```

---

## Rollout Plan

1. **Phase 1 first** - Auto-imports are low-risk and immediately useful
2. **Phase 2 incrementally** - Merge one feature at a time, test each
3. **Phase 3 optional** - Standardize naming only if it becomes painful
4. **Phase 4** - Final directory reorganization after features stabilize

## Success Criteria

- [ ] Adding a new module = create file, done (no import list editing)
- [ ] Finding "everything about X" = one file to read
- [ ] Enabling feature on new host = `modules.X.enable = true`
- [ ] All existing systems still build and deploy correctly

## Risks

| Risk | Mitigation |
|------|------------|
| Breaking existing configs | Keep old option paths as aliases |
| Auto-import picks up unwanted files | Use `_` prefix convention for excluded files |
| Home-manager context unavailable | Only merge where `home-manager.users.X` works |

---

## References

- [Dendritic Pattern](https://github.com/mightyiam/dendritic)
- [import-tree](https://github.com/vic/import-tree)
- [flake.parts modules](https://flake.parts/options/flake-parts-modules.html)
