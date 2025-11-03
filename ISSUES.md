# Issues & Todo Tracker

**Last Updated:** November 2, 2025  
**Priority Legend:** 🔴 Critical | 🟠 High | 🟡 Medium | 🟢 Low | 💡 Idea

---

## 🔴 Critical Priority

### System Stability

- [x] **Hyprlock keeps crashing**
  - Priority: 🔴 Critical
  - Status: ✅ FIXED (November 2, 2025)
  - Solution: Added PAM service for hyprlock in Hyprland module
  - Root Cause: Missing `/etc/pam.d/hyprlock` PAM module causing authentication failures
  - Fix Location: `modules/system/windowManagers/hyprland.nix`
  - Tags: `hyprland`, `security`, `crash`

### Security

- [x] **fail2ban not running or not accessible**
  - Priority: 🔴 Critical
  - Status: ✅ FIXED (November 2, 2025)
  - Solution: Added fail2ban configuration in security module with hardening.enable option
  - Impact: SSH brute-force protection now active on Cortex (server)
  - Configuration: maxretry=3, local network whitelisted, SSH jail enabled
  - Location: `modules/system/system/security.nix`, enabled in `systems/cortex/default.nix`
  - Tags: `security`, `services`, `fail2ban`

- [x] **auditd not running or not accessible**
  - Priority: 🔴 Critical  
  - Status: ✅ FIXED (November 2, 2025)
  - Solution: Added auditd configuration in security module with hardening.enable option
  - Impact: System call auditing now active on Cortex for security monitoring
  - Monitors: auth logs, SSH config, sudo usage, user/group changes
  - Location: `modules/system/system/security.nix`, enabled in `systems/cortex/default.nix`
  - Tags: `security`, `services`, `auditd`

- [ ] **sshd appears not running (but connection works)**
  - Priority: 🟠 High
  - Impact: Status reporting inconsistency, monitoring issues
  - Investigation: `systemctl status sshd` vs actual connection
  - Note: Connected via SSH, so it's running - status reporting issue
  - Tags: `ssh`, `monitoring`

---

## 🟠 High Priority

### Hardware & Drivers

- [ ] **Audio not switching channels when Bluetooth connected/disconnected**
  - Priority: 🟠 High
  - Status: ⏳ IN PROGRESS (November 2, 2025)
  - Investigation: Added WirePlumber priority config, but device won't reconnect after WirePlumber restart
  - Symptoms:
    - Bluetooth device (TOZO Open EarRing) paired but won't connect
    - Connection timeout: `br-connection-page-timeout`
    - WirePlumber logs show "invalid profile" errors
    - Bluetooth daemon shows Hands-Free gateway profile issues
  - Potential causes:
    - Device needs to be in pairing mode after WirePlumber restart
    - Profile compatibility issue (HFP/HSP vs A2DP)
    - Auto-reconnect not working properly
  - Location: `modules/system/hardware/audio.nix`
  - Tags: `audio`, `bluetooth`, `pipewire`, `wireplumber`

### User Experience

- [ ] **Volume control shows multiple notifications**
  - Priority: 🟠 High
  - Status: ✅ FIXED (November 2, 2025)
  - Impact: Notification spam when adjusting volume
  - Solution: Likely duplicate notification services
  - Investigation: Check dunst/mako configuration, volume-control.sh script
  - Tags: `notifications`, `ux`

- [ ] **Mullvad VPN not showing in system tray**
  - Priority: 🟠 High
  - Impact: Can't easily see VPN status or control connection
  - Root Cause: Mullvad GUI (Electron app) uses temp file paths for system tray icons (e.g., `/tmp/.org.chromium.Chromium.*/logo.png`)
  - Investigation Findings:
    - Mullvad daemon IS running (`mullvad-daemon.service`)
    - Mullvad GUI IS running (PID check shows GUI processes)
    - StatusNotifier items ARE registered on D-Bus (confirmed via `org.kde.StatusNotifierWatcher`)
    - HyprPanel receives the tray registration but can't load the icon
    - Error: "cannot assign file:///tmp/.org.chromium.Chromium.LNaTE5/logo.png as icon, it is not a file nor a named icon"
  - Workaround: Use `mullvad` CLI for VPN control (`mullvad status`, `mullvad connect`, `mullvad disconnect`)
  - Potential Fixes (not yet implemented):
    - Try alternative bar/systray (waybar, eww) that might handle Electron temp icons better
    - Patch Mullvad to use named icons instead of temp files (upstream issue)
    - Use `mullvad-exclude` wrapper to launch GUI with different tray implementation
  - Related: Known Electron/Wayland systray limitation
  - Tags: `vpn`, `gui`, `systray`, `wayland`, `electron`, `upstream`

### Configuration Issues

- [x] **LibreWolf profile warning on every rebuild**
  - Priority: 🟠 High  
  - Status: ✅ RESOLVED (November 2, 2025) - Harmless warning
  - Error: `config.stylix.targets.librewolf.profileNames` is not set
  - Resolution: This is just an informational warning from stylix. LibreWolf works
 perfectly fine without stylix theming. The warning can be safely ignored.
  - Note: Stylix's librewolf target is for theming but requires profile configuration
 that isn't easily accessible in our current setup. Not worth fixing.
  - Tags: `warnings`, `stylix`, `librewolf`

---

## 🟡 Medium Priority

### Security Enhancements

- [ ] **deploy-rs has NO autoRollback configured in flake.nix**
  - Priority: 🟡 Medium
  - Impact: Failed deployments don't automatically rollback
  - Risk: System could be left in broken state on remote deploy
  - Fix: Add `autoRollback = true;` to deploy-rs configuration
  - Location: `flake.nix` deploy-rs profiles
  - Related: [FLEET-MANAGEMENT.md](./FLEET-MANAGEMENT.md)
  - Tags: `deploy-rs`, `safety`, `automation`

- [ ] **Remote access VPN not yet configured**
  - Priority: 🟡 Medium
  - Impact: No secure remote access to home network
  - Options: WireGuard, Tailscale, ZeroTier
  - Recommendation: Tailscale for simplicity or WireGuard for control
  - Tags: `vpn`, `remote-access`, `security`

- [ ] **Network security testing & VLAN segmentation**
  - Priority: 🟡 Medium
  - Impact: Improved network security posture
  - Goal: Segment IoT devices, guests, and trusted devices
  - Requirements: VLAN-capable router/switch, firewall rules
  - Tags: `networking`, `security`, `vlan`

### Development & Testing

- [ ] **Build VMs for testing new configurations**
  - Priority: 🟡 Medium
  - Impact: Safe testing environment before deploying to production
  - Options: `nixos-rebuild build-vm`, `machinectl`, Proxmox VMs
  - Related: `machines` NixOS feature, `systemd-nspawn`
  - Tags: `testing`, `vms`, `dev-environment`
  - See: [TODO-CHECKLIST.md](./docs/TODO-CHECKLIST.md) - Testing & Validation section

### Security Tooling

- [x] **Integrate git-secrets for repo scanning**
  - Priority: 🟡 Medium
  - Status: ✅ INTEGRATED (November 2, 2025)
  - Impact: Prevents committing secrets to git
  - Solution: Pre-commit hook active at `.git/hooks/pre-commit`, auto-configured patterns in devenv.nix
  - Usage: Automatic on every commit, manual scan with `git secrets --scan`
  - Location: `scripts/git-hooks/pre-commit`, `devenv.nix`
  - Tags: `security`, `git`, `secrets`

- [x] **Integrate TruffleHog for secret scanning**
  - Priority: 🟡 Medium
  - Status: ✅ INTEGRATED (November 2, 2025)
  - Impact: Deep historical secret detection in git history
  - Solution: Available in devenv (v3.90.9), convenience script created
  - Usage: `./scripts/security-scan.sh [quick|full|history]`
  - Documentation: `docs/SECURITY-SCANNING.md`
  - Location: `devenv.nix`, `scripts/security-scan.sh`
  - Tags: `security`, `git`, `secrets`

---

## 🟢 Low Priority / Quality of Life

### Hardware & Peripherals

- [ ] **Fingerprint sensor integration**
  - Priority: 🟢 Low
  - Impact: Biometric authentication for login/sudo
  - Requirements: Compatible fingerprint reader, fprintd
  - Related: PAM configuration
  - Tags: `hardware`, `authentication`, `biometrics`

### Applications

- [x] **Disable Brave BAT ads**
  - Priority: 🟢 Low
  - Status: ✅ FIXED (November 2, 2025)
  - Impact: Cleaner browsing experience
  - Solution: Added `--disable-brave-rewards` and `--disable-brave-rewards-extension` flags to commandLineArgs
  - Location: `modules/home/programs/brave.nix`
  - Tags: `brave`, `browser`, `ux`

### CLI Enhancements

- [ ] **Mullvad VPN: Launch applications with VPN tunneling from CLI**
  - Priority: 🟢 Low
  - Impact: Per-application VPN routing
  - Investigation: `mullvad-exclude` command or network namespaces
  - Use case: Route specific apps through VPN
  - Tags: `vpn`, `cli`, `networking`

---

## 💡 Future Ideas / Backlog

### Home Automation

- [ ] **Home Assistant for smart outlet monitoring**
  - Priority: 💡 Idea
  - Impact: Power monitoring, automation capabilities
  - Requirements: Smart outlets, Home Assistant instance
  - Platform: Could run on Cortex or dedicated Pi
  - Tags: `home-automation`, `monitoring`, `iot`

### Gaming & Services

- [ ] **AMP game server**
  - Priority: 💡 Idea
  - Impact: Self-hosted game server management
  - Platform: Likely Cortex or future Proxmox VMs
  - Note: CubeCoders AMP is commercial, alternatives exist
  - Tags: `gaming`, `services`, `self-hosted`

---

## ✅ Recently Completed

### November 2, 2025

- [x] **Hyprlock keeps crashing**
  - Fixed: Added missing PAM service for hyprlock
  - Root Cause: Missing `/etc/pam.d/hyprlock` causing authentication failures
  - Solution: Added PAM configuration in Hyprland module
  - Impact: Screen lock now works reliably without crashes

- [x] **Volume shows multiple notifications**
  - Fixed: Consolidated notification system
  - Impact: Clean single notification on volume change

- [x] **Hypridle not turning off monitors overnight**
  - Fixed: Implemented lock-aware DPMS script
  - Solution: `scripts/dpms-off-if-locked.sh` with per-listener ignore_inhibit

- [x] **fail2ban and auditd security hardening** (November 2, 2025)
  - Fixed: Added security.hardening module with fail2ban and auditd
  - Impact: SSH brute-force protection and security event auditing on Cortex
  - Solution: Modular hardening.enable option for server-specific security

- [x] **Disable Brave BAT ads** (November 2, 2025)
  - Fixed: Added command-line flags to disable Brave Rewards
  - Solution: Added `--disable-brave-rewards` and `--disable-brave-rewards-extension` to brave.nix
  - Impact: Cleaner browsing experience without BAT ad notifications

- [x] **git-secrets and TruffleHog integration** (November 2, 2025)
  - Fixed: Integrated both secret scanning tools with automation
  - Solution: Pre-commit hooks active, convenience script created, comprehensive documentation
  - Tools: git-secrets (pre-commit) + TruffleHog v3.90.9 (manual/CI)
  - Scripts: `scripts/security-scan.sh`, `scripts/git-hooks/pre-commit`
  - Documentation: `docs/SECURITY-SCANNING.md`
  - Impact: Prevents accidental secret commits and enables deep historical scanning

---

## 📋 Issue Management

### How to Use This Tracker

1. **Adding Issues**: Copy a template from above, fill in details
2. **Updating Status**: Change `[ ]` to `[x]` when complete
3. **Priority Changes**: Update 🔴🟠🟡🟢💡 emoji as needed
4. **Moving Items**: Move to "Recently Completed" when done
5. **Regular Review**: Weekly review and reprioritize

### Issue Template

```markdown
- [ ] **Issue Title**
  - Priority: 🔴/🟠/🟡/🟢/💡
  - Impact: What's affected?
  - Investigation: Where to start looking
  - Location: Relevant files/modules
  - Tags: `tag1`, `tag2`, `tag3`
```

### Related Documentation

- [TODO-CHECKLIST.md](./docs/TODO-CHECKLIST.md) - Implementation roadmap
- [ARCHITECTURE.md](./docs/ARCHITECTURE.md) - System architecture
- [FLEET-MANAGEMENT.md](./FLEET-MANAGEMENT.md) - Deployment workflows
- [SECURITY.md](./docs/SECURITY.md) - Security configuration

---

**Notes:**
- Review and update this file weekly
- Move stale items to backlog or archive
- Keep critical issues visible at the top
- Cross-reference with TODO-CHECKLIST.md for implementation tasks
