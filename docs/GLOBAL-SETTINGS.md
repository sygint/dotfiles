# Global Settings Configuration

## Overview
This document describes how global settings like timezone and locale are centralized across all NixOS systems in this flake.

## Centralized Configuration: `fleet-config.nix`

All global settings are defined in `/fleet-config.nix` in the `global` section:

```nix
{
  global = {
    timeZone = "America/Los_Angeles";  # Pacific Time
    locale = "en_US.UTF-8";
  };
  
  network = { ... };
  hosts = { ... };
}
```

## Usage in System Configurations

Each system imports and uses these global settings:

```nix
# In systems/*/default.nix
{ config, pkgs, lib, ... }:
let
  networkConfig = import ../../fleet-config.nix;
in
{
  # Use global timezone
  time.timeZone = networkConfig.global.timeZone;
  
  # Use global locale (optional)
  i18n.defaultLocale = networkConfig.global.locale;
}
```

## Benefits

1. **Single Source of Truth**: Change timezone once, applies everywhere
2. **Consistency**: All systems use the same time settings
3. **Easy Updates**: Modify `fleet-config.nix` and rebuild
4. **Type Safety**: Nix ensures the value exists and is valid

## Current Configuration

- **Timezone**: `America/Los_Angeles` (Pacific Time)
- **Locale**: `en_US.UTF-8`

## Systems Using Global Settings

All systems now use the centralized configuration:
- ✅ Orion (workstation)
- ✅ Cortex (AI server)
- ✅ Nexus (homelab server)
- ✅ Axon (media center)

## Changing the Global Timezone

To change the timezone for all systems:

1. Edit `fleet-config.nix`:
   ```nix
   global = {
     timeZone = "America/New_York";  # Change to your timezone
     locale = "en_US.UTF-8";
   };
   ```

2. Rebuild all systems:
   ```bash
   # Rebuild local system
   sudo nixos-rebuild switch --flake .
   
   # Deploy to remote systems
   ./scripts/fleet.sh update cortex
   ./scripts/fleet.sh update nexus
   ./scripts/fleet.sh update axon
   
   # Or deploy all at once
   nix run github:serokell/deploy-rs -- .
   ```

## Available Timezones

Common US timezones:
- `America/New_York` - Eastern Time
- `America/Chicago` - Central Time
- `America/Denver` - Mountain Time
- `America/Los_Angeles` - Pacific Time
- `America/Anchorage` - Alaska Time
- `Pacific/Honolulu` - Hawaii Time

To see all available timezones:
```bash
timedatectl list-timezones
```

## Per-System Overrides

If you need a specific system to use a different timezone (e.g., a server running in a different location), you can override it:

```nix
# In systems/specific-system/default.nix
{
  # Override the global timezone for this system only
  time.timeZone = lib.mkForce "UTC";
}
```

## Related Configuration

Other settings that could be centralized in `fleet-config.nix`:
- Default DNS servers
- NTP servers
- Common firewall rules
- Shared SSH keys
- Domain names

## See Also

- [fleet-config.nix](../fleet-config.nix) - Centralized network and global settings
- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture overview
- [FLEET-MANAGEMENT.md](../FLEET-MANAGEMENT.md) - Managing multiple systems
