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

- [ ] **fail2ban not running or not accessible**
  - Priority: 🔴 Critical
  - Impact: No brute-force protection on exposed services
  - Investigation: `systemctl status fail2ban`
  - Related: Security hardening
  - Tags: `security`, `services`

- [ ] **auditd not running or not accessible**
  - Priority: 🔴 Critical  
  - Impact: No system call auditing for security events
  - Investigation: `systemctl status auditd`
  - Related: Security compliance
  - Tags: `security`, `services`

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
  - Impact: Manual audio switching required, poor UX
  - Expected: Auto-switch to Bluetooth when connected, back to speakers when disconnected
  - Investigation: Check PipeWire/WirePlumber rules
  - Related: Desktop usability
  - Tags: `audio`, `bluetooth`, `pipewire`
  - Potential Solution: WirePlumber device switching rules

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
  - Investigation: Check if mullvad-gui is in system tray programs
  - Related: `modules/home/programs/`
  - Tags: `vpn`, `gui`, `systray`

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

- [ ] **Integrate git-secrets for repo scanning**
  - Priority: 🟡 Medium
  - Status: Available in devenv but not enforced
  - Impact: Prevent committing secrets to git
  - Location: Add to pre-commit hooks
  - Tags: `security`, `git`, `secrets`

- [ ] **Integrate TruffleHog for secret scanning**
  - Priority: 🟡 Medium
  - Status: Available in devenv (version 3.90.9)
  - Impact: Historical secret detection in git history
  - Usage: `trufflehog git file://.`
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

- [ ] **Disable Brave BAT ads**
  - Priority: 🟢 Low
  - Impact: Cleaner browsing experience
  - Fix: Brave settings or declarative browser config
  - Location: `modules/home/programs/brave.nix` if exists
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
