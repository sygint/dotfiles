# Testing Scripts

Scripts for testing NixOS configurations in isolated environments.

## Scripts

### test-vm.sh
Build and run a VM for testing configurations with GUI support.

**Usage:**
```bash
./scripts/testing/test-vm.sh <system-name> [memory-mb] [cpu-cores]
```

**Examples:**
```bash
# Basic usage
./scripts/testing/test-vm.sh htpc

# With custom resources
./scripts/testing/test-vm.sh htpc 4096 4

# Test desktop system
./scripts/testing/test-vm.sh orion 8192 4
```

**Best for:**
- Testing GUI/desktop configurations
- Hyprland/Waybar configurations
- Display manager setups
- Full system integration testing

### test-container.sh
Manage NixOS containers for lightweight service testing.

**Usage:**
```bash
./scripts/testing/test-container.sh <system-name> <action>
```

**Actions:**
- `create` - Create a new container
- `start` - Start the container
- `stop` - Stop the container
- `shell` - Open a shell in the container
- `status` - Show container status
- `destroy` - Remove the container
- `list` - List all containers

**Examples:**
```bash
# Create and start a container
./scripts/testing/test-container.sh htpc create
./scripts/testing/test-container.sh htpc start

# Get a shell inside
./scripts/testing/test-container.sh htpc shell

# Check status
./scripts/testing/test-container.sh htpc status

# Clean up
./scripts/testing/test-container.sh htpc stop
./scripts/testing/test-container.sh htpc destroy

# List all containers
./scripts/testing/test-container.sh list
```

**Best for:**
- Testing headless services
- API server configurations
- System services
- Network services
- Quick iteration without GUI overhead

## Testing Workflow

### For Desktop/GUI Systems:
```bash
# Edit configuration
vim systems/orion/default.nix

# Test in VM
./scripts/testing/test-vm.sh orion

# If good, deploy
just deploy orion
```

### For Headless/Services:
```bash
# Edit configuration
vim systems/cortex/default.nix

# Test in container
./scripts/testing/test-container.sh cortex create
./scripts/testing/test-container.sh cortex start
./scripts/testing/test-container.sh cortex shell

# If good, deploy
just deploy cortex

# Clean up
./scripts/testing/test-container.sh cortex destroy
```

## VM vs Container

| Feature | VM | Container |
|---------|----|-----------| 
| GUI Support | ✅ Yes | ❌ No |
| Resource Usage | Higher | Lower |
| Boot Time | Slower | Faster |
| Isolation | Full | Process-level |
| Best For | Desktop configs | Service configs |

## See Also
- [docs/VM-TESTING.md](../../docs/VM-TESTING.md) - Detailed testing documentation
- [ISSUES.md](../../ISSUES.md) - Issue #10: VM Testing Framework
