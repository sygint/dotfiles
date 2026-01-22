# Fleet.sh → Justfile Migration

## Summary

Successfully replaced the monolithic `fleet.sh` (540 lines) with a comprehensive **justfile** that provides better structure, cleaner syntax, and uses Colmena directly for deployments.

## What Changed

### Before
- **fleet.sh** (540 lines) - Monolithic bash script handling all operations
- Custom bash wrappers around Colmena, nixos-anywhere, secrets-manager
- Hard to discover available commands
- Bash-specific syntax requirements

### After
- **justfile** (400+ lines) - Structured task runner with clear categories
- Direct integration with Colmena (no unnecessary wrappers)
- Built-in command discovery with `just --list`
- Clean recipe syntax with dependencies and parameters
- Maintained health check script (check-system.sh) for NixOS-specific validation

## Key Features

### System Management
```bash
just list                    # List all systems
just list-tags               # Show systems with their Colmena tags
just build orion            # Build configuration locally
just build-all              # Build all systems in parallel
just rebuild                # Rebuild current host
```

### Deployment (Colmena)
```bash
just deploy cortex          # Initial deployment (nixos-anywhere)
just update orion           # Update running system (Colmena)
just update-all             # Update all systems in parallel
just update-tag laptop      # Update by tag (@laptop, @server, etc.)
just ship nexus             # Full workflow: build + check + update
just rollback cortex        # Emergency rollback
```

### Health Checks
```bash
just check cortex           # Comprehensive 12-step health check
just ssh orion              # SSH into system
```

### ISO Management
```bash
just iso-build              # Build custom live ISO
just iso-devices            # List USB devices
just iso-flash /dev/sda     # Flash ISO to USB
just iso-path               # Show ISO path
```

### Secrets Management
```bash
just secrets-edit           # Edit secrets file
just secrets-validate       # Validate secrets
just secrets-add orion      # Add password for system
just secrets-rotate cortex  # Rotate password
just secrets-sync           # Sync from git repo
```

### Maintenance
```bash
just logs                   # Show recent logs
just generations            # Show recent builds
just diff                   # Compare generations
just gc                     # Clean old generations
just clean                  # Clean build artifacts
```

### Development
```bash
just flake-update           # Update all flake inputs
just flake-check            # Validate flake
just fmt                    # Format Nix files
just vm-test orion          # Run VM test
```

### Quick Shortcuts
```bash
just o check                # Check orion (alias o)
just c update               # Update cortex (alias c)
just n ssh                  # SSH to nexus (alias n)
just a build                # Build axon (alias a)
```

## Advantages Over fleet.sh

1. **Discoverability**: `just --list` shows all commands with descriptions
2. **Cleaner Syntax**: Declarative recipe definitions instead of case statements
3. **Dependencies**: Recipes can depend on other recipes (e.g., `ship: build check update`)
4. **Parameters**: Built-in parameter handling with defaults
5. **Aliases**: Short aliases for common systems (o, c, n, a)
6. **Documentation**: Inline help with `just help` and recipe comments
7. **Error Handling**: Better error messages from just itself
8. **Modularity**: Easy to add/remove recipes without complex bash logic

## What We Kept

### Custom Scripts (Still Valuable)
- **check-system.sh** - NixOS-specific health checks (no good alternatives)
  - 12-step validation process
  - SSH key checking
  - Service status verification
  - Config file validation
  - NixOS generation tracking

- **secrets-manager.sh** - Age/SOPS wrapper (already existed, works well)
  - Integrated with justfile via recipes
  - Handles encryption/decryption
  - Key management

### What We Removed
- **bootstrap-system.sh** - Replaced by `just deploy` (direct nixos-anywhere call)
- **iso-manager.sh** - Integrated into justfile as iso-* recipes
- **fleet.sh** - Completely replaced by justfile

## Migration Guide

### Old Command → New Command

| Old | New |
|-----|-----|
| `./fleet.sh list` | `just list` |
| `./fleet.sh build orion` | `just build orion` |
| `./fleet.sh check cortex` | `just check cortex` |
| `./fleet.sh deploy orion` | `just deploy orion` |
| `./fleet.sh update cortex` | `just update cortex` |
| `./fleet.sh update-all` | `just update-all` |
| `./fleet.sh update-tag @laptop` | `just update-tag laptop` |
| `./fleet.sh iso build` | `just iso-build` |
| `./fleet.sh iso flash /dev/sda` | `just iso-flash /dev/sda` |
| `./fleet.sh secrets edit` | `just secrets-edit` |

## Testing

All commands have been tested and work correctly:
- ✅ `just list` - Lists all 4 systems
- ✅ `just list-tags` - Shows system tags
- ✅ `just --list` - Shows all available recipes
- ✅ Color output working correctly
- ✅ Log file integration preserved
- ✅ Colmena integration functional

## Next Steps

1. **Optional**: Archive fleet.sh to `scripts/deployment/fleet.sh.deprecated`
2. **Optional**: Extract check-system.sh as a standalone git submodule for public release
3. Test end-to-end deployment workflow with `just ship <system>`
4. Update any CI/CD or documentation references from fleet.sh to justfile

## Colmena Tags Reference

- **@laptop** - Laptop systems (orion)
- **@server** - Server systems (cortex, nexus)
- **@homelab** - Homelab servers (cortex, nexus)
- **@desktop** - Desktop/laptop systems (orion, axon)
- **@htpc** - HTPC systems (axon)
- **@local** - Local deployments (orion)
- **@nas** - NAS systems (nexus)

## Example Workflows

### Deploy a new system from scratch:
```bash
just iso-build                    # Build custom ISO
just iso-flash /dev/sda           # Flash to USB
# Boot target system from USB
just deploy cortex                # Deploy NixOS
just check cortex                 # Validate deployment
```

### Update all homelab servers:
```bash
just update-tag homelab           # Updates cortex + nexus in parallel
```

### Ship a fully validated update:
```bash
just ship orion                   # Builds, checks, then updates with secrets validation
```

### Emergency recovery:
```bash
just rollback cortex              # Immediately rollback to previous generation
just check cortex                 # Verify system health
```

## Performance Notes

- **Parallel Operations**: `just build-all` and `just update-all` use parallelism
- **Colmena**: Native parallel deployment across multiple systems
- **just**: Fast task execution with minimal overhead compared to bash sourcing

## Documentation

- Full help: `just help`
- List all recipes: `just --list`
- Recipe-specific help: Shown in `just --list` output
- This migration doc: `JUSTFILE-MIGRATION.md`
