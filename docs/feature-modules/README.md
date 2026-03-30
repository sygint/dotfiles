# Feature Module Examples

This directory contains example feature modules demonstrating various patterns and use cases.

## Examples

### 1. Simple Feature (`simple.nix`)
Basic feature module that installs a package and creates a user configuration file.

**Use when:** You need a straightforward feature with minimal configuration.

### 2. Feature with Service (`with-service.nix`)
Feature module that runs a systemd service, opens firewall ports, and provides client tools.

**Use when:** Your feature needs to run a background service.

### 3. Complex Feature (`complex.nix`)
Advanced feature module with multiple options, conditional features, and complex configuration generation.

**Use when:** Your feature needs extensive customization options.

## Usage

These examples are for reference only. To create a new feature module:

1. **Use the template:**
   ```bash
   cp modules/features/_TEMPLATE.nix modules/features/myfeature.nix
   ```

2. **Or copy an example:**
   ```bash
   cp examples/feature-modules/simple.nix modules/features/myfeature.nix
   ```

3. **Customize the module** for your needs

4. **Enable in your system:**
   ```nix
   # systems/orion/default.nix
   modules.features.myfeature.enable = true;
   ```

5. **Test and apply:**
   ```bash
   nix flake check
   sudo nixos-rebuild switch --flake .#orion
   ```

## Real-World Examples

Check out the actual feature modules in `modules/features/` for production examples:

**Simple features:**
- `git.nix` - Git with user configuration
- `btop.nix` - System monitor
- `printing.nix` - CUPS printing

**Service features:**
- `mullvad.nix` - VPN service + browser
- `syncthing.nix` - File synchronization
- `containerization.nix` - Docker/Podman

**Complex features:**
- `hyprland.nix` - Wayland compositor with extensive config
- `networking.nix` - NetworkManager with multiple options
- `vscode.nix` - Code editor with extensions

## Documentation

For complete documentation on the feature module pattern, see:
- **[../docs/DENDRITIC-MIGRATION.md](../docs/DENDRITIC-MIGRATION.md)** - Complete migration guide
- **[../docs/ARCHITECTURE.md](../docs/ARCHITECTURE.md)** - Architecture documentation
- **[../modules/features/_TEMPLATE.nix](../modules/features/_TEMPLATE.nix)** - Template file

## Pattern Guidelines

### File Structure
```nix
{
  config, lib, pkgs, userVars, ...
}:

let
  cfg = config.modules.features.<name>;
in
{
  options.modules.features.<name> = {
    enable = mkEnableOption "<description>";
    # Additional options...
  };

  config = mkIf cfg.enable {
    # System config
    # User config via home-manager.users.${userVars.username}
  };
}
```

### Best Practices

1. **Single Responsibility**: One feature per module
2. **Self-Contained**: Include all related configuration
3. **Optional by Default**: Always use `mkIf cfg.enable`
4. **Use Variables**: Leverage `userVars` for user-specific values
5. **Document Options**: Provide clear descriptions
6. **Sensible Defaults**: Provide good defaults, allow overrides

### Common Patterns

**System + User Config:**
```nix
config = mkIf cfg.enable {
  # System
  services.myservice.enable = true;
  
  # User
  home-manager.users.${userVars.username} = {
    programs.myclient.enable = true;
  };
};
```

**Conditional Features:**
```nix
environment.systemPackages = mkIf cfg.enableExtra [
  pkgs.extra-tool
];
```

**List Options:**
```nix
${lib.concatMapStringsSep "\n" (item: "- ${item}") cfg.items}
```

**Generated Config Files:**
```nix
home.file.".config/app/config.json".text = builtins.toJSON cfg.settings;
```
