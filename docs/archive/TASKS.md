# NixOS Fleet Tasks

Simple task tracking for the NixOS fleet management system. Just edit this file in your editor.

**Quick Commands:**
- View: `cat TASKS.md` or `glow TASKS.md` (if you have glow installed)
- Edit: `$EDITOR TASKS.md`
- Search: `grep "TODO\|FIXME" -r .`

---

## 🔥 Urgent / Blocking

*Nothing here - if something is blocking you, add it here!*

---

## 📋 Active Work

- [ ] **VM Testing & Validation Automation** (Started: 2025-11-18)
  - Add persistent VM build/launch to fleet.sh for real console/SSH testing
  - Current vm-test only runs ephemeral test VMs
  - Next: Add `fleet.sh vm-launch <system>` command

- [ ] **Self-host Plane for Project Management** (Added: 2025-11-18)
  - Deploy Plane on Nexus (192.168.1.22) once infrastructure is stable
  - Needs: Docker, PostgreSQL, Redis, MinIO
  - Replace this markdown file with proper project management

---

## 💡 Backlog / Ideas

- [ ] Secrets management improvements (sops-nix, better rotation)
- [ ] Fleet logging enhancements (centralized, structured)
- [ ] TUI dashboard for fleet status
- [ ] VM snapshot management
- [ ] Automated backup validation
- [ ] Integration tests across multiple systems

---

## ✅ Done

- [x] Fixed VM test to handle missing variables/home-manager (2025-11-18)
- [x] Virtualization module now uses lib.optionalAttrs for safety (2025-11-18)

---

## 🚫 Blocked / On Hold

*Nothing here currently*

---

## 📝 Quick Notes

- Check fleet status: `./scripts/deployment/fleet.sh list`
- Run VM test: `./scripts/deployment/fleet.sh vm-test <system>`
- Deploy system: `./scripts/deployment/fleet.sh deploy <system>`

