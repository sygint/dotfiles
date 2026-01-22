# VM and Container Testing Guide

**Last Updated:** November 2, 2025

This guide covers different methods for testing NixOS configurations in isolated environments before deploying to physical hardware.

---

## 🎯 Quick Reference

| Method | Speed | Isolation | GUI | Use Case |
|--------|-------|-----------|-----|----------|
| `nixos-rebuild build-vm` | Fast | Full VM | ✅ Yes | Quick GUI testing |
| NixOS Containers | Fastest | Shared kernel | ❌ No | Headless services |
| systemd-nspawn | Fast | Shared kernel | ⚠️ Limited | System testing |
| QEMU/KVM (virt-manager) | Medium | Full VM | ✅ Yes | Production-like testing |
| Proxmox VMs | Slow | Full VM | ✅ Yes | Long-term testing |

---

## 🚀 Method 1: Quick VM Testing (`nixos-rebuild build-vm`)

**Best for:** Rapid testing of desktop/GUI configurations, HTPC testing

### How It Works
Creates a lightweight QEMU VM from your NixOS configuration with minimal setup.

### Usage

```bash
# Build VM for a specific system
nixos-rebuild build-vm --flake .#htpc

# The output will show the VM script location
# Example: /nix/store/.../bin/run-htpc-vm

# Run the VM
./result/bin/run-htpc-vm

# Or with more memory
QEMU_OPTS="-m 4096" ./result/bin/run-htpc-vm
```

### VM Options

```bash
# More RAM
QEMU_OPTS="-m 8192" ./result/bin/run-htpc-vm

# With KVM acceleration (much faster)
QEMU_OPTS="-enable-kvm -m 4096" ./result/bin/run-htpc-vm

# With specific network
QEMU_OPTS="-netdev user,id=net0,hostfwd=tcp::8080-:80" ./result/bin/run-htpc-vm

# With shared folder
QEMU_OPTS="-virtfs local,path=/home/user/shared,mount_tag=host0,security_model=passthrough,id=host0" ./result/bin/run-htpc-vm
```

### Configuration for VM Testing

Add to your system configuration (e.g., `systems/htpc/default.nix`):

```nix
# Optimize for VM testing
virtualisation.vmVariant = {
  # More resources for VM
  virtualisation = {
    memorySize = 4096;  # 4GB RAM
    cores = 4;          # 4 CPU cores
    
    # Disk size
    diskSize = 10000;   # 10GB
    
    # Graphics
    qemu = {
      options = [
        "-vga virtio"
        "-display sdl,gl=on"
      ];
    };
  };
  
  # Skip time-consuming services in VM
  services.xserver.videoDrivers = lib.mkForce [ "modesetting" ];
};
```

### Pros & Cons

✅ **Pros:**
- Very fast to build and iterate
- Full isolation from host
- Perfect for GUI/desktop testing
- No persistent state (starts fresh each time)
- Works with Hyprland, GNOME, etc.

❌ **Cons:**
- Ephemeral (no state persistence)
- Network isolation by default
- Not suitable for long-running tests
- Hardware differences from real machine

---

## 🐳 Method 2: NixOS Containers

**Best for:** Testing headless services, daemons, network configurations

### How It Works
Lightweight containers using systemd-nspawn that share the host kernel but provide isolated userspace.

### Configuration

Create a container configuration file:

```nix
# containers.nix - Add to your system config
{
  containers.test-htpc = {
    autoStart = false;  # Manual start
    ephemeral = true;   # Temporary, destroyed on stop
    
    config = { config, pkgs, ... }: {
      # Import your HTPC configuration
      imports = [ ./systems/htpc/default.nix ];
      
      # Container-specific overrides
      system.stateVersion = "24.11";
      
      # Network configuration
      networking = {
        useHostResolvConf = true;
        interfaces.eth0.useDHCP = true;
      };
    };
    
    # Bind mounts for shared data
    bindMounts = {
      "/mnt/nas" = {
        hostPath = "/home/user/test-nas";
        isReadOnly = false;
      };
    };
  };
}
```

### Usage

```bash
# Start container
sudo nixos-container start test-htpc

# Get container IP
sudo nixos-container show-ip test-htpc

# Run command in container
sudo nixos-container run test-htpc -- jellyfin --version

# Open shell in container
sudo nixos-container root-login test-htpc

# Stop container
sudo nixos-container stop test-htpc

# Destroy container
sudo nixos-container destroy test-htpc

# List all containers
sudo nixos-container list
```

### Container Management Commands

```bash
# Update container config
sudo nixos-container update test-htpc

# Check container status
sudo nixos-container status test-htpc

# Show container configuration
sudo nixos-container show-ip test-htpc
systemctl status container@test-htpc
```

### Pros & Cons

✅ **Pros:**
- Very lightweight and fast
- Shares host kernel (efficient)
- Good for service testing
- Can have persistent or ephemeral storage
- Network isolation

❌ **Cons:**
- No GUI support (headless only)
- Shares kernel with host
- Limited hardware emulation
- Not suitable for desktop environments

---

## 🖥️ Method 3: systemd-nspawn (Manual Container)

**Best for:** Advanced testing, custom container setups

### Create Container Manually

```bash
# Create container directory
sudo mkdir -p /var/lib/machines/htpc-test

# Bootstrap minimal NixOS
sudo nix-build '<nixpkgs/nixos>' \
  -A system \
  -I nixos-config=./systems/htpc/default.nix \
  -o /var/lib/machines/htpc-test/system

# Boot container
sudo systemd-nspawn -D /var/lib/machines/htpc-test \
  --boot \
  --network-veth \
  --bind=/tmp/.X11-unix

# Or use machinectl
sudo machinectl start htpc-test
sudo machinectl shell htpc-test
```

### Machinectl Commands

```bash
# List machines
machinectl list

# Start/stop machine
sudo machinectl start htpc-test
sudo machinectl stop htpc-test

# Get shell
sudo machinectl shell htpc-test

# Show machine status
machinectl status htpc-test

# Show machine properties
machinectl show htpc-test

# Remove machine
sudo machinectl remove htpc-test
```

### Pros & Cons

✅ **Pros:**
- More control than declarative containers
- Can test complex scenarios
- Good for debugging
- Fast startup

❌ **Cons:**
- More manual setup
- Limited GUI support
- Requires more knowledge
- Less reproducible than `nixos-rebuild build-vm`

---

## 🖥️ Method 4: QEMU/KVM with virt-manager

**Best for:** Production-like testing, long-running tests, hardware emulation

### Prerequisites

Your Orion system already has virtualization enabled:
```nix
services.virtualization = {
  enable = true;
  service = "qemu";
  username = "syg";
};
```

### Create VM with virt-manager

1. **Launch virt-manager:**
   ```bash
   virt-manager
   ```

2. **Create new VM:**
   - File → New Virtual Machine
   - Choose "Import existing disk image" or "Network install"
   - For NixOS: Use minimal ISO or network install

3. **Configure VM:**
   - RAM: 4-8GB
   - CPUs: 2-4 cores
   - Disk: 20-50GB
   - Network: NAT or bridged

4. **Install NixOS:**
   - Boot the VM
   - Follow standard NixOS installation
   - Or use your automated bootstrap

### Deploy Configuration to VM

```bash
# Get VM IP address
# In VM: ip addr show

# Deploy from Orion to VM
sudo nixos-rebuild switch --flake .#htpc \
  --target-host root@<vm-ip> \
  --build-host localhost

# Or use deploy-rs
# Add VM to flake.nix deploy.nodes first
nix run github:serokell/deploy-rs -- .#htpc-vm
```

### VM Snapshots

```bash
# Create snapshot
virsh snapshot-create-as htpc-test snap1 "Before config change"

# List snapshots
virsh snapshot-list htpc-test

# Revert to snapshot
virsh snapshot-revert htpc-test snap1

# Delete snapshot
virsh snapshot-delete htpc-test snap1
```

### Pros & Cons

✅ **Pros:**
- Full hardware emulation
- Persistent storage
- Snapshots for easy rollback
- Production-like environment
- GUI support

❌ **Cons:**
- Slower than containers
- Requires more resources
- More setup time
- Requires full NixOS installation

---

## 🎬 HTPC-Specific Testing Workflow

### Recommended Approach

**Phase 1: Quick Validation (build-vm)**
```bash
# Build and test HTPC config
cd ~/.config/nixos
nixos-rebuild build-vm --flake .#htpc

# Run VM with more resources
QEMU_OPTS="-enable-kvm -m 4096 -smp 4" ./result/bin/run-htpc-vm

# Test:
# - Boot process (auto-login)
# - Jellyfin Media Player launches
# - Kiosk mode works
# - Audio/video playback
```

**Phase 2: Service Testing (Container)**
```bash
# For testing specific services without GUI
sudo nixos-container create htpc-test --config-file ./systems/htpc/default.nix
sudo nixos-container start htpc-test

# Test:
# - Network connectivity
# - NFS/SMB mounts
# - Service dependencies
```

**Phase 3: Full System Test (virt-manager)**
```bash
# Create full VM for production-like testing
# Install NixOS, deploy config, test extensively

# Test:
# - Hardware acceleration
# - CEC control
# - TV remote integration
# - Long-term stability
```

### Testing Checklist

**Boot & Display:**
- [ ] System boots successfully
- [ ] Auto-login to kiosk user works
- [ ] Display manager launches
- [ ] Jellyfin Media Player starts fullscreen

**Media Playback:**
- [ ] Jellyfin connects to server
- [ ] Video playback works
- [ ] Audio output correct
- [ ] Hardware acceleration enabled

**Network:**
- [ ] Network connectivity
- [ ] NAS mounts accessible
- [ ] Jellyfin server reachable
- [ ] Firewall rules work

**Security:**
- [ ] Kiosk user has limited permissions
- [ ] Admin user can login (TTY2)
- [ ] No unexpected services running
- [ ] Firewall configured correctly

---

## 🔧 Helper Scripts

### Build and Run VM Script

Create `scripts/test-vm.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

SYSTEM="${1:-htpc}"
MEMORY="${2:-4096}"
CORES="${3:-4}"

echo "🔨 Building VM for $SYSTEM..."
nixos-rebuild build-vm --flake .#"$SYSTEM"

if [ -L result ]; then
    echo "✅ VM built successfully"
    echo "🚀 Starting VM with ${MEMORY}MB RAM and ${CORES} cores..."
    QEMU_OPTS="-enable-kvm -m $MEMORY -smp $CORES" ./result/bin/run-${SYSTEM}-vm
else
    echo "❌ VM build failed"
    exit 1
fi
```

### Container Testing Script

Create `scripts/test-container.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

CONTAINER_NAME="test-${1:-htpc}"
ACTION="${2:-start}"

case "$ACTION" in
    create)
        echo "📦 Creating container $CONTAINER_NAME..."
        sudo nixos-container create "$CONTAINER_NAME" \
          --config-file "./systems/${1}/default.nix"
        ;;
    start)
        echo "▶️  Starting container $CONTAINER_NAME..."
        sudo nixos-container start "$CONTAINER_NAME"
        echo "🌐 Container IP: $(sudo nixos-container show-ip $CONTAINER_NAME)"
        ;;
    shell)
        echo "💻 Opening shell in $CONTAINER_NAME..."
        sudo nixos-container root-login "$CONTAINER_NAME"
        ;;
    stop)
        echo "⏸️  Stopping container $CONTAINER_NAME..."
        sudo nixos-container stop "$CONTAINER_NAME"
        ;;
    destroy)
        echo "🗑️  Destroying container $CONTAINER_NAME..."
        sudo nixos-container destroy "$CONTAINER_NAME"
        ;;
    *)
        echo "Usage: $0 <system-name> {create|start|shell|stop|destroy}"
        exit 1
        ;;
esac
```

---

## 📊 Comparison Matrix

### When to Use Each Method

**Build-VM:**
- ✅ Quick config changes
- ✅ Desktop/GUI testing
- ✅ HTPC kiosk mode
- ✅ Display manager testing
- ❌ Persistent data
- ❌ Hardware-specific testing

**Containers:**
- ✅ Service testing
- ✅ Network configuration
- ✅ Daemon behavior
- ✅ Multiple instances
- ❌ GUI applications
- ❌ Kernel differences

**systemd-nspawn:**
- ✅ Custom scenarios
- ✅ Advanced debugging
- ✅ System behavior
- ✅ Quick iteration
- ❌ Complex setup
- ❌ GUI support

**QEMU/KVM:**
- ✅ Production-like
- ✅ Hardware emulation
- ✅ Long-term testing
- ✅ Full isolation
- ❌ Resource intensive
- ❌ Slower builds

---

## 🎓 Best Practices

1. **Start Small:** Use `build-vm` for initial testing
2. **Iterate Quickly:** Containers for service debugging
3. **Test Realistically:** Full VMs before physical deployment
4. **Use Snapshots:** Save known-good states
5. **Automate Tests:** Create scripts for common test scenarios
6. **Document Results:** Keep notes on what works/fails
7. **Clean Up:** Remove unused VMs and containers regularly

---

## 🔗 Related Documentation

- [HTPC-SETUP.md](./HTPC-SETUP.md) - HTPC deployment guide
- [BOOTSTRAP.md](./BOOTSTRAP.md) - System bootstrap procedures
- [FLEET-MANAGEMENT.md](../FLEET-MANAGEMENT.md) - Fleet deployment
- [NixOS Manual - NixOS Containers](https://nixos.org/manual/nixos/stable/#ch-containers)
- [NixOS Manual - QEMU](https://nixos.org/manual/nixos/stable/#sec-qemu-guest)

---

## 🆘 Troubleshooting

### VM Won't Boot
```bash
# Check QEMU options
QEMU_OPTS="-enable-kvm -m 4096" ./result/bin/run-htpc-vm

# Try without KVM
./result/bin/run-htpc-vm

# Check for errors
journalctl -xe
```

### Container Fails to Start
```bash
# Check container status
systemctl status container@test-htpc

# Check logs
journalctl -u container@test-htpc

# Rebuild container
sudo nixos-container update test-htpc
```

### Network Issues in VM
```bash
# Use userspace networking
QEMU_OPTS="-netdev user,id=net0,hostfwd=tcp::8080-:8096" ./result/bin/run-htpc-vm

# Or bridge networking (requires permissions)
# See NixOS manual for bridge setup
```

### GUI Not Working in Container
Containers are headless by default. Use `build-vm` for GUI testing or set up X11/Wayland forwarding (complex).

---

**Pro Tip:** Combine methods! Use `build-vm` for quick checks, containers for service testing, and full VMs for final validation before hardware deployment.
