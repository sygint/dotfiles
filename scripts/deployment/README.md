# Deployment Scripts

Scripts for deploying and managing NixOS fleet updates.

## Fleet Management

Fleet management is handled by the `fleet` CLI tool ([nixos-fleet](https://github.com/sygint/nixos-fleet)), which is installed as a flake input.

```bash
fleet status              # Show all systems
fleet check cortex        # Health check
fleet push cortex         # Deploy updates
fleet install cortex 192.168.1.7  # Fresh install (⚠️ wipes disk!)
```

For complete documentation, see the [README](../../README.md).

## Scripts
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
2. **Deploy:** `fleet push cortex`
3. **Validate:** `./scripts/deployment/validate.sh cortex 192.168.1.7 jarvis`

Or use the all-in-one safe deploy:
```bash
./scripts/deployment/safe-deploy.sh cortex 192.168.1.7 jarvis
```

## See Also
- [README](../../README.md) - Fleet management overview
- [docs/BOOTSTRAP.md](../../docs/BOOTSTRAP.md) - Bootstrap new systems
