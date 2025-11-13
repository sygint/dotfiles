# Bootstrap Scripts

Scripts for setting up new NixOS systems from scratch.

## Scripts

### bootstrap-nixos.sh
Remote NixOS installation on target machines using this nix-config.

**Usage:**
```bash
./scripts/bootstrap/bootstrap-nixos.sh -n <hostname> -d <destination>
```

**Example:**
```bash
./scripts/bootstrap/bootstrap-nixos.sh -n cortex -d 192.168.1.7 -u jarvis
```

### bootstrap-automated.sh
Fully automated bootstrap process with minimal interaction.

**Usage:**
```bash
./scripts/bootstrap/bootstrap-automated.sh <hostname> <ip-address>
```

**Example:**
```bash
./scripts/bootstrap/bootstrap-automated.sh cortex 192.168.1.34
```

### bootstrap-devenv.sh
Sets up the development environment with all necessary tools and dependencies.

**Usage:**
```bash
./scripts/bootstrap/bootstrap-devenv.sh
```

## See Also
- [docs/BOOTSTRAP.md](../../docs/BOOTSTRAP.md) - Complete bootstrap documentation
- [FLEET-MANAGEMENT.md](../../FLEET-MANAGEMENT.md) - Fleet management guide
