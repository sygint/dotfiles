# Issues Tracker

Open bugs and known issues across the NixOS fleet.

---

## Open Issues

### sshd Status Reporting Inconsistency

**Priority:** Medium
**System:** Cortex

`systemctl status sshd` reports not running, but SSH connections work fine. Status reporting / monitoring issue only.

---

## Recently Fixed

- **Bluetooth Audio** -- added BlueZ reconnect settings (FastConnectable, ReconnectAttempts, ReconnectIntervals) for reliable audio device reconnection (Feb 2026)

- **Fingerprint sensor** -- fprintd enabled via nixos-hardware Framework module, PAM integration active for sudo/swaylock/SDDM, fingerprints enrolled (Feb 2026)

- **Hyprlock crashing** -- added missing PAM service (Nov 2025)
- **Volume multiple notifications** -- consolidated notification system (Nov 2025)
- **Hypridle not turning off monitors** -- lock-aware DPMS script (Nov 2025)
- **fail2ban / auditd not running on Cortex** -- added security.hardening module (Nov 2025)
- **Brave BAT ads** -- disabled via command-line flags (Nov 2025)
- **git-secrets / TruffleHog integration** -- pre-commit hooks + scanning script (Nov 2025)
- **LibreWolf Stylix warning** -- harmless, ignored (Nov 2025)

---

## Known Limitations

### Mullvad VPN System Tray

**System:** Orion

Mullvad GUI (Electron) uses temp file paths for system tray icons. HyprPanel receives tray registration but can't load the icon from `/tmp/.org.chromium.Chromium.*/logo.png`.

- Daemon and GUI both running, D-Bus registration works
- Workaround: use `mullvad` CLI (`mullvad status`, `mullvad connect`)
- Root cause: Electron/Wayland systray limitation (upstream, unfixable)
