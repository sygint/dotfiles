# TODO: Migrate to nixos-fleet

**Date Created**: 2026-01-22  
**Status**: Not Started  
**Priority**: Medium  
**Estimated Effort**: 2-4 hours

---

## Overview

This repository should be using **nixos-fleet** (`~/Projects/open-source/nixos-fleet`) for deployment, but is currently using **deploy-rs** directly. nixos-fleet provides a unified CLI and uses Colmena under the hood.

**Why migrate:**
- ✅ Unified `fleet` CLI instead of custom bash scripts
- ✅ Colmena-powered parallel deployments
- ✅ Tag-based targeting (`fleet push --tag servers`)
- ✅ Better secrets management integration
- ✅ ISO generation support
- ✅ Battle-tested patterns from your own project

---

## Current State

### What We Have Now
- **Deployment**: `deploy-rs` via `flake-modules/deploy.nix`
- **Fleet Management**: Custom `scripts/deployment/fleet.sh` (bash wrapper)
- **Fleet Config**: `fleet-config.nix` (good - compatible with nixos-fleet)
- **Systems**: Orion, Cortex, Nexus, Axon

### What's Missing
- nixos-fleet not added as flake input
- No Colmena configuration
- No `fleet` CLI available
- Custom fleet.sh lacks secrets management

---

## nixos-fleet Features

From `~/Projects/open-source/nixos-fleet/README.md`:

### CLI Commands
```bash
fleet push <host>          # Deploy updates (Colmena)
fleet install <host>       # Fresh install (nixos-anywhere)
fleet check <host>         # Health check
fleet iso                  # Generate installer ISO
fleet rekey                # Rotate secrets
fleet --tag servers push   # Deploy to tagged hosts
```

### Library Functions
```nix
nixos-fleet.lib.mkFleet    # Main builder
nixos-fleet.lib.generateHosts
nixos-fleet.lib.generateColmena
```

### Modules
```nix
nixosModules.fleet-hosts         # Auto-generate /etc/hosts
nixosModules.fleet-deploy-user   # Setup deploy user
```

---

## Migration Steps

### Phase 1: Add nixos-fleet Input (15 min)

1. **Add flake input** to `flake.nix`:
   ```nix
   inputs = {
     # ... existing inputs
     nixos-fleet.url = "github:sygint/nixos-fleet";
     # Or local dev: nixos-fleet.url = "path:/home/syg/Projects/open-source/nixos-fleet";
   };
   ```

2. **Pass to flake-parts**:
   ```nix
   outputs = inputs@{ flake-parts, ... }:
     flake-parts.lib.mkFlake { inherit inputs; } {
       # ...
     };
   ```

3. **Test**: `nix flake lock --update-input nixos-fleet`

---

### Phase 2: Migrate to mkFleet (1-2 hours)

#### Option A: Full Migration (Recommended)

Replace entire flake structure with `nixos-fleet.lib.mkFleet`:

**Before** (`flake.nix`):
```nix
outputs = inputs@{ flake-parts, ... }:
  flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [
      ./flake-modules/nixos-configurations.nix
      ./flake-modules/home-configurations.nix
      ./flake-modules/deploy.nix
    ];
  };
```

**After**:
```nix
outputs = { nixpkgs, nixos-fleet, home-manager, ... }@inputs:
  let
    fleetConfig = import ./fleet-config.nix;
  in
  nixos-fleet.lib.mkFleet {
    inherit inputs;
    
    fleet = {
      network = fleetConfig.network;
      hosts = fleetConfig.hosts;
    };
    
    # Per-host configurations
    hostConfigurations = {
      orion = ./systems/orion;
      cortex = ./systems/cortex;
      nexus = ./systems/nexus;
      axon = ./systems/axon;
    };
  };
```

#### Option B: Gradual Migration

Keep flake-parts but use nixos-fleet utilities:

```nix
outputs = inputs@{ flake-parts, nixos-fleet, ... }:
  let
    fleetLib = nixos-fleet.lib;
    fleetConfig = import ./fleet-config.nix;
  in
  flake-parts.lib.mkFlake { inherit inputs; } {
    imports = [
      ./flake-modules/nixos-configurations.nix
      ./flake-modules/home-configurations.nix
    ];
    
    # Replace deploy.nix with Colmena
    flake.colmena = fleetLib.generateColmena {
      inherit inputs;
      fleet = {
        network = fleetConfig.network;
        hosts = fleetConfig.hosts;
      };
    };
  };
```

---

### Phase 3: Install Fleet CLI (5 min)

Add to system packages or dev shell:

```nix
# In systems/orion/default.nix or flake devShell
{
  environment.systemPackages = [
    inputs.nixos-fleet.packages.${system}.fleet
  ];
}
```

Or use directly:
```bash
nix run ~/Projects/open-source/nixos-fleet#fleet -- push cortex
```

---

### Phase 4: Update Scripts & Docs (30 min)

1. **Update justfile** to use `fleet` CLI:
   ```justfile
   # Deploy to specific host
   deploy-cortex:
       fleet push cortex
   
   # Deploy to all servers
   deploy-servers:
       fleet push --tag server
   ```

2. **Archive old fleet.sh**:
   ```bash
   mv scripts/deployment/fleet.sh scripts/deployment/archive/fleet.sh.old
   ```

3. **Update documentation**:
   - Update `docs/BOOTSTRAP.md` to reference `fleet install`
   - Create `docs/FLEET-MANAGEMENT.md` with nixos-fleet commands
   - Update README with new deployment workflow

---

### Phase 5: Enable Fleet Modules (15 min)

Add nixos-fleet modules to systems:

```nix
# In flake-modules/nixos-configurations.nix
{
  imports = [
    inputs.nixos-fleet.nixosModules.fleet-hosts     # Auto /etc/hosts
    inputs.nixos-fleet.nixosModules.fleet-deploy-user  # Deploy user setup
  ];
}
```

---

## Compatibility Check

### What Works Already ✅
- ✅ `fleet-config.nix` structure is compatible
- ✅ System configurations in `systems/*/` work as-is
- ✅ Home-manager configurations compatible
- ✅ sops-nix secrets work with nixos-fleet

### What Needs Adjustment ⚠️
- ⚠️ Custom `deploy.nix` → Colmena configuration
- ⚠️ `scripts/deployment/fleet.sh` → `fleet` CLI
- ⚠️ deploy-rs usage → Colmena usage

---

## Testing Strategy

### 1. Test on Non-Critical Host First
Start with Axon (media center - least critical):

```bash
# Build configuration
nix build .#nixosConfigurations.axon.config.system.build.toplevel

# Test deploy (dry-run if available)
fleet check axon

# Deploy
fleet push axon
```

### 2. Verify Health Checks
```bash
fleet check axon
ssh axon 'systemctl status'
```

### 3. Roll Out to Other Hosts
- Axon (done) → Nexus (homelab) → Cortex (AI) → Orion (workstation)

---

## Rollback Plan

If migration fails:

1. **Revert flake.nix**:
   ```bash
   git checkout HEAD~1 flake.nix
   nix flake lock
   ```

2. **Use old deploy-rs**:
   ```bash
   nix run github:serokell/deploy-rs -- .#<host>
   ```

3. **Restore fleet.sh**:
   ```bash
   git restore scripts/deployment/fleet.sh
   ```

---

## Open Questions

- [ ] Should we use Option A (full migration) or Option B (gradual)?
- [ ] Do we want local dev path or GitHub URL for nixos-fleet input?
- [ ] Should we add tags to hosts in fleet-config.nix?
  ```nix
  hosts.cortex.tags = [ "server" "ai" "remote" ];
  hosts.nexus.tags = [ "server" "homelab" "remote" ];
  hosts.axon.tags = [ "media" "local" ];
  hosts.orion.tags = [ "workstation" "local" ];
  ```
- [ ] Do we want to use nixos-fleet's ISO generation for liveiso?

---

## Benefits After Migration

1. **Simplified Deployment**: `fleet push cortex` instead of `nix run github:serokell/deploy-rs -- .#cortex`
2. **Parallel Deploys**: `fleet push --tag server` deploys Cortex + Nexus simultaneously
3. **Better Tooling**: Built-in health checks, secrets management
4. **Dogfooding**: Use your own project in production
5. **Unified Workflow**: Same commands across all operations

---

## Next Steps

1. **Immediate** (today):
   - [ ] Decide on Option A vs Option B
   - [ ] Add nixos-fleet as flake input
   - [ ] Test `nix build` still works

2. **This Week**:
   - [ ] Implement chosen migration option
   - [ ] Test deploy on Axon
   - [ ] Update documentation

3. **This Month**:
   - [ ] Migrate all hosts
   - [ ] Archive old fleet.sh
   - [ ] Add tags to fleet-config.nix
   - [ ] Create blog post about the migration

---

## References

- **nixos-fleet**: `~/Projects/open-source/nixos-fleet`
- **nixos-fleet README**: `~/Projects/open-source/nixos-fleet/README.md`
- **Current fleet-config**: `fleet-config.nix`
- **Current deploy config**: `flake-modules/deploy.nix`
- **Colmena docs**: https://colmena.cli.rs/

---

## Updates

**2026-01-22**: Initial migration plan created. Currently using deploy-rs directly.
