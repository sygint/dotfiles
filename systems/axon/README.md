# Axon Media Center

## Purpose
Axon is the living room media center, running NixOS and optimized for streaming from the Synology NAS via Jellyfin. It provides a secure, user-friendly Kiosk mode for family/media use.

## Hardware
- Mini PC (Intel/AMD, integrated GPU)
- HDMI output to TV
- CEC support for TV remote integration

## Key Services & Features
- Jellyfin Media Player (Kiosk mode)
- Kodi, VLC, MPV for media playback
- PipeWire audio, hardware video acceleration
- Auto-login Kiosk user, secure admin user
- Power management and CEC integration

## Deployment
- Build and deploy with:
  ```bash
  nixos-rebuild switch --flake .#axon --target-host root@<axon-ip>
  # Or with deploy-rs:
  nix run github:serokell/deploy-rs -- --targets .#axon
  ```
- Hardware config in `hardware.nix`
- User config in `homes/axon.nix` and `homes/kiosk.nix`

## User Accounts
- `axon`: Admin user (wheel, audio, video)
- `kiosk`: Restricted media user (no sudo)

## Security Notes
- Kiosk user has no sudo, minimal privileges
- Firewall enabled, only media ports open
- Secrets managed via sops-nix (not in repo)

## Troubleshooting & Tips
- See `AXON-SETUP.md` for setup and troubleshooting
- Use `vainfo` to check video acceleration
- Use `kiosk-admin` to switch from kiosk to admin

## References
- [AXON-SETUP.md](../../docs/AXON-SETUP.md)
- [Homelab Strategy](../../docs/planning/homelab-strategy.md)
