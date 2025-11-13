# Scripts

This directory contains all utility scripts organized by category.

## Directory Structure

```
scripts/
├── bootstrap/         # System installation and setup
├── deployment/        # Fleet management and deployment
├── desktop/          # Desktop utilities (monitors, bluetooth, etc.)
├── power/            # Power and idle management
├── statusbar/        # Status bar launchers
├── browser/          # Browser optimization
├── development/      # Development environment setup
├── kanboard/         # Kanboard API integration
├── testing/          # VM and container testing
├── security/         # Security scanning
├── network/          # Network utilities
├── utils/            # Miscellaneous utilities
├── git-hooks/        # Git hooks for validation
└── archive/          # Deprecated/old scripts
```

## Quick Reference

### Bootstrap & Setup
- **[bootstrap/bootstrap-nixos.sh](bootstrap/)** - Remote NixOS installation
- **[bootstrap/bootstrap-automated.sh](bootstrap/)** - Fully automated bootstrap
- **[bootstrap/bootstrap-devenv.sh](bootstrap/)** - Dev environment setup

### Deployment
- **[deployment/fleet.sh](deployment/)** - Fleet management tool
- **[deployment/safe-deploy.sh](deployment/)** - Safe deployment orchestration
- **[deployment/pre-flight.sh](deployment/)** - Pre-deployment checks
- **[deployment/validate.sh](deployment/)** - Post-deployment validation

### Desktop
- **[desktop/monitors.sh](desktop/)** - Monitor configuration
- **[desktop/bluetooth-tui.sh](desktop/)** - Bluetooth management
- **[desktop/network-tui.sh](desktop/)** - Network management
- **[desktop/screenshot.sh](desktop/)** - Screenshot tool
- **[desktop/volume-control.sh](desktop/)** - Volume control

### Power Management
- **[power/dpms-off-if-locked.sh](power/)** - Smart DPMS control
- **[power/check-idle-blockers.sh](power/)** - Idle troubleshooting

### Testing
- **[testing/test-vm.sh](testing/)** - VM testing for GUI configs
- **[testing/test-container.sh](testing/)** - Container testing for services

### Security
- **[security/security-scan.sh](security/)** - Secret scanning with git-secrets and TruffleHog

## Category Details

Each subdirectory contains its own README.md with detailed documentation:

- **[bootstrap/README.md](bootstrap/README.md)** - System installation procedures
- **[deployment/README.md](deployment/README.md)** - Fleet deployment workflows
- **[desktop/README.md](desktop/README.md)** - Desktop utility details
- **[power/README.md](power/README.md)** - Power management configuration
- **[statusbar/README.md](statusbar/README.md)** - Status bar setup
- **[browser/README.md](browser/README.md)** - Browser optimization guide
- **[development/README.md](development/README.md)** - Development environment
- **[kanboard/README.md](kanboard/README.md)** - Kanboard API usage
- **[testing/README.md](testing/README.md)** - Testing framework
- **[security/README.md](security/README.md)** - Security tools
- **[network/README.md](network/README.md)** - Network utilities
- **[utils/README.md](utils/README.md)** - Miscellaneous tools

## Common Workflows

### Initial System Setup
```bash
# Bootstrap a new system
./scripts/bootstrap/bootstrap-nixos.sh -n hostname -d 192.168.1.X -u username

# Setup development environment
./scripts/development/setup-dev-environment.sh
```

### Daily Development
```bash
# Test changes in VM
./scripts/testing/test-vm.sh orion

# Deploy to remote system
just deploy cortex
# or
./scripts/deployment/safe-deploy.sh cortex 192.168.1.7 jarvis
```

### Fleet Management
```bash
# List all systems
./scripts/deployment/fleet.sh list

# Check system health
./scripts/deployment/fleet.sh check cortex

# Deploy updates
./scripts/deployment/fleet.sh update cortex
```

### Troubleshooting
```bash
# Check what's preventing idle/sleep
./scripts/power/check-idle-blockers.sh

# Scan for secrets before commit
./scripts/security/security-scan.sh quick

# Fix WiFi after undocking
./scripts/network/fix-wifi-after-undock.sh
```

## See Also

- [FLEET-MANAGEMENT.md](../FLEET-MANAGEMENT.md) - Complete fleet management guide
- [docs/BOOTSTRAP.md](../docs/BOOTSTRAP.md) - Bootstrap documentation
- [docs/VM-TESTING.md](../docs/VM-TESTING.md) - Testing framework details
- [docs/SECURITY-SCANNING.md](../docs/SECURITY-SCANNING.md) - Security scanning guide
- [CONTRIBUTING.md](../CONTRIBUTING.md) - Development workflow

