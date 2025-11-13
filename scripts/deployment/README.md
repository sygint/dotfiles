# Deployment Scripts

Scripts for deploying and managing NixOS fleet updates.

## Scripts

### fleet.sh
Main fleet management tool for deploying configurations across multiple systems.

**Usage:**
```bash
./scripts/deployment/fleet.sh <command> [args]
```

**Commands:**
- `list` - List all systems
- `build <system>` - Build config locally
- `check <system>` - Check system health
- `update <system>` - Deploy updates to system
- `deploy <system> <ip>` - Fresh install (⚠️ wipes disk!)

**Examples:**
```bash
./scripts/deployment/fleet.sh list
./scripts/deployment/fleet.sh build cortex
./scripts/deployment/fleet.sh update cortex
```

For complete documentation, see [FLEET-MANAGEMENT.md](../../FLEET-MANAGEMENT.md)

### safe-deploy.sh
Orchestrates pre-flight checks, deployment, and validation for safer deployments.

**Usage:**
```bash
./scripts/deployment/safe-deploy.sh <host> <ip> <user>
```

**Example:**
```bash
./scripts/deployment/safe-deploy.sh cortex 192.168.1.7 jarvis
```

### pre-flight.sh
Pre-deployment validation checks to ensure system is ready for updates.

**Usage:**
```bash
./scripts/deployment/pre-flight.sh <host> <ip> <user>
```

**Example:**
```bash
./scripts/deployment/pre-flight.sh cortex 192.168.1.7 jarvis
```

### validate.sh
Post-deployment validation to confirm system is healthy after updates.

**Usage:**
```bash
./scripts/deployment/validate.sh <host> <ip> <user>
```

**Example:**
```bash
./scripts/deployment/validate.sh cortex 192.168.1.7 jarvis
```

## Workflow

The recommended deployment workflow:

1. **Pre-flight check:** `./scripts/deployment/pre-flight.sh cortex 192.168.1.7 jarvis`
2. **Deploy:** `nixos-rebuild switch` or `./scripts/deployment/fleet.sh update cortex`
3. **Validate:** `./scripts/deployment/validate.sh cortex 192.168.1.7 jarvis`

Or use the all-in-one safe deploy:
```bash
./scripts/deployment/safe-deploy.sh cortex 192.168.1.7 jarvis
```

## See Also
- [FLEET-MANAGEMENT.md](../../FLEET-MANAGEMENT.md)
- [docs/IMPLEMENTATION-GUIDE.md](../../docs/IMPLEMENTATION-GUIDE.md)
