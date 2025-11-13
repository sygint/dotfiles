# Utility Scripts

Miscellaneous utility scripts that don't fit other categories.

## Scripts

### just-global
Global justfile that can be symlinked to `~/.justfile` for system-wide just commands.

**Setup:**
```bash
ln -sf ~/.config/nixos/scripts/utils/just-global ~/.justfile
```

**Usage:**
```bash
# From anywhere in your system
just <command>
```

See the file contents for available global commands.

### start-mullvad-delayed.sh
Starts Mullvad VPN with a delay, useful for system startup to ensure network is ready first.

**Usage:**
```bash
./scripts/utils/start-mullvad-delayed.sh
```

**What it does:**
- Waits for network to be available
- Starts Mullvad VPN daemon
- Connects to VPN
- Logs activity

**Auto-start:**
This can be configured in your system configuration to run on startup:
```nix
systemd.user.services.mullvad-delayed = {
  description = "Start Mullvad VPN with delay";
  after = [ "network-online.target" ];
  wantedBy = [ "default.target" ];
  serviceConfig.ExecStart = "${pkgs.bash}/bin/bash ${configRoot}/scripts/utils/start-mullvad-delayed.sh";
};
```

## See Also
- [justfile](../../justfile) - Main project justfile
- System configuration files in `systems/`
