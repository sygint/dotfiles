# Backlog

Future improvements and aspirational items. Not prioritized -- just captured so they don't get lost.

---

## Infrastructure

- **Automated Borg backups** to Synology DS-920+ for all systems
- **Monitoring stack on Nexus** -- AdGuard Home, Grafana, Prometheus, Loki
- **HTTPS for internal services** -- reverse proxy with SSL termination (see [TODO-HTTPS-MIGRATION.md](TODO-HTTPS-MIGRATION.md))
- **Colmena backend migration** -- complete nixos-fleet Colmena integration for parallel deployment (see [TODO-NIXOS-FLEET-MIGRATION.md](TODO-NIXOS-FLEET-MIGRATION.md))

## Security

- **Remote access VPN** -- Headscale or Tailscale for secure access to home network
- **VLAN segmentation** -- separate IoT, guest, and trusted device networks (UDM Pro)
- **YubiKey integration** -- physical 2FA for sudo and SSH
- **AppArmor sandboxing** -- application-level security policies

## Home Automation

- **Home Assistant** -- smart outlet monitoring, automation
- **Frigate NVR** -- network video recording and security cameras

## Development Workflow

- **Pre-commit hooks** -- nixfmt, statix, deadnix
- **CI/CD** -- automated configuration testing on push
- **VM testing** -- test configurations in disposable VMs before deploying
- **Example repos** -- public nixos-fleet-example and nixos-config-example templates

## Hardware

- ~~**Fingerprint sensor**~~ -- Framework 13 fprintd + PAM integration ✓

## Someday

- Stable channel pinning for production services (Jellyfin, etc.)
- Custom Nix library functions (`lib/`)
- Multi-user configurations on shared systems
- Offsite backups
