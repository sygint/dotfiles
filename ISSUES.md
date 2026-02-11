# Issues Tracker

Open bugs and known issues across the NixOS fleet.

---

## Open Issues

### Bluetooth Audio Channel Switching

**Priority:** High
**System:** Orion

Audio doesn't switch channels when Bluetooth devices connect/disconnect. WirePlumber priority config added but device won't reconnect after WirePlumber restart. TOZO Open EarRing shows `br-connection-page-timeout` and "invalid profile" errors.

- Potential causes: device needs pairing mode after WirePlumber restart, HFP/HSP vs A2DP profile issue, auto-reconnect broken
- Location: `modules/features/audio.nix`

### Mullvad VPN Not in System Tray

**Priority:** High
**System:** Orion

Mullvad GUI (Electron) uses temp file paths for system tray icons. HyprPanel receives tray registration but can't load the icon from `/tmp/.org.chromium.Chromium.*/logo.png`.

- Daemon and GUI both running, D-Bus registration works
- Workaround: use `mullvad` CLI (`mullvad status`, `mullvad connect`)
- Root cause: Electron/Wayland systray limitation (upstream)

### sshd Status Reporting Inconsistency

**Priority:** Medium
**System:** Cortex

`systemctl status sshd` reports not running, but SSH connections work fine. Status reporting / monitoring issue only.

### Fingerprint Sensor

**Priority:** Low
**System:** Orion

Framework 13 fingerprint reader not configured. Requires fprintd and PAM integration.

---

## Recently Fixed

- **Hyprlock crashing** -- added missing PAM service (Nov 2025)
- **Volume multiple notifications** -- consolidated notification system (Nov 2025)
- **Hypridle not turning off monitors** -- lock-aware DPMS script (Nov 2025)
- **fail2ban / auditd not running on Cortex** -- added security.hardening module (Nov 2025)
- **Brave BAT ads** -- disabled via command-line flags (Nov 2025)
- **git-secrets / TruffleHog integration** -- pre-commit hooks + scanning script (Nov 2025)
- **LibreWolf Stylix warning** -- harmless, ignored (Nov 2025)
