# Custom NixOS Installer ISO

A minimal NixOS installer ISO with SSH pre-configured for remote provisioning with `nixos-anywhere`.

## Purpose

This ISO enables the following workflow:
1. **Boot**: Insert USB drive and boot target machine
2. **Connect**: ISO automatically enables SSH with your authorized keys
3. **Provision**: Run `nixos-anywhere` from your workstation to install NixOS
4. **Manage**: Use `deploy-rs` for all subsequent updates

## Setup

### 1. Add Your SSH Public Key

Edit `flake.nix` and replace the placeholder with your actual SSH public key:

```nix
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJxxx... user@host"
];
```

To get your public key:
```bash
cat ~/.ssh/id_ed25519.pub
# or
cat ~/.ssh/id_rsa.pub
```

### 2. Build the ISO

```bash
cd systems/custom-live-iso
nix build .#nixosConfigurations.installer.config.system.build.isoImage
```

The ISO will be in `./result/iso/nixos-anywhere-installer.iso`

### 3. Flash to USB Drive

```bash
# Find your USB device (e.g., /dev/sdb)
lsblk

# Flash the ISO (replace /dev/sdX with your device)
sudo dd if=result/iso/nixos-anywhere-installer.iso of=/dev/sdX bs=4M status=progress
sudo sync
```

## Usage

### Boot the Target Machine

1. Insert the USB drive into the target machine
2. Boot from the USB drive
3. Wait for the system to boot (network will auto-configure via DHCP)
4. Find the IP address (check your DHCP server/router)

### Run nixos-anywhere

From your workstation:

```bash
# Test SSH connection first
ssh root@<target-ip>

# Run nixos-anywhere to provision the machine
nixos-anywhere --flake '.#your-host' root@<target-ip>
```

### Subsequent Updates

After initial provisioning, use `deploy-rs`:

```bash
./scripts/fleet.sh deploy your-host
```

## Security Notes

- **SSH Keys**: Only the root user's authorized keys are configured
- **Fallback Password**: A default password "nixos" is set as fallback (change it in flake.nix)
- **Network**: Ethernet only, WiFi disabled for simplicity
- **Temporary**: This is a live system - nothing persists after reboot

## Customization

### Add More Packages

Edit the `environment.systemPackages` section in `flake.nix`:

```nix
environment.systemPackages = with pkgs; [
  vim
  git
  curl
  # Add more packages here
  parted
  gptfdisk
];
```

### Enable WiFi

If you need WiFi support:

```nix
networking.wireless.enable = true;
networking.wireless.networks = {
  "YourSSID" = {
    psk = "YourPassword";
  };
};
```

## Troubleshooting

### Can't SSH In

1. Check the network: `ip addr` on the target machine console
2. Verify SSH service: `systemctl status sshd`
3. Check authorized keys: `cat /root/.ssh/authorized_keys`
4. Try fallback password: `ssh root@<ip>` with password "nixos"

### ISO Won't Boot

- Verify USB was flashed correctly
- Check BIOS/UEFI boot order
- Try UEFI vs Legacy boot mode

### Build Fails

Make sure you're using Nix with flakes enabled:
```bash
nix --version  # Should be 2.4 or later
```
