# Deployment Workflow: Summary & Implementation Plan

## Summary
- Only the `deploy` user is allowed remote SSH access for deployments, with passwordless sudo and trusted-users membership.
- The `rescue` user (formerly admin) is for physical console/KVM access only, with a password set via secrets and no SSH keys.
- All deployments are initiated from a trusted local machine using the deploy user and SSH key.
- SSH key propagation, sudo, and trusted-users are enforced and checked in config/scripts.
- Recovery/bootstrapping is documented for when remote access is broken.

## Implementation Plan
1. **Enforce user roles in NixOS configs:**
   - Ensure only deploy has SSH access and passwordless sudo.
   - Rescue user is console-only, no SSH keys.
2. **Automate SSH key and sudo checks:**
   - Add scripts to verify deploy user SSH and sudo before deployment.
3. **Document and test recovery steps:**
   - Keep recovery plan up to date and test after major changes.
4. **Iterate and improve:**
   - Update documentation and scripts as workflow evolves.

---

# Deployment Workflow: Pain Points, Goals, Constraints, and Solutions

## 1. Pain Points

- **Remote vs Local Deployment Confusion:**
  - Unclear when to use local vs remote deployment tools (deploy-rs, nixos-anywhere, etc.).
  - Frustration when remote tools are suggested but local access would be simpler.

- **SSH and Sudo Permissions Hell:**
  - Passwordless sudo for the deploy user is required, but not always set up or working.
  - Admin user also lacks passwordless sudo, blocking remote activation.
  - Rescue user is console-only, so can't be used for remote fixes.

- **Credential/Key Propagation:**
  - SSH keys sometimes not accepted, or too many authentication failures.
  - Unclear which user (admin, deploy, rescue) is valid for each step.

- **Nix Trusted Users:**
  - Nix store copy/activation fails unless deploy user is in `trusted-users`.
  - Can't update trusted-users without a working deploy.

- **Password Management:**
  - Initial passwords only work on first boot, not reliable after that.
  - No clear recovery if all remote sudo access is lost.

- **Error Feedback Loops:**
  - Errors only visible after long build/copy/deploy cycles.
  - Error messages are not always actionable or clear.

- **Tooling Frustration:**
  - Annoyance at tools/AI for not understanding local/remote context or suggesting impossible steps.

## 2. Goals

- Enable reliable, repeatable, and secure deployment to all systems (especially headless/remote).
- Ensure deploy user always has passwordless sudo and is in trusted-users.
- Make it clear which user/key is used for each deployment step.
- Provide a robust recovery/bootstrapping path if remote sudo/ssh is broken.
- Minimize manual intervention and error-prone steps.
- Document the workflow and recovery steps for future reference.

## 3. Constraints

- Some systems are headless or remote (no easy console/KVM access).
- Security: avoid leaving passwordless sudo open to all users.
- Initial passwords may be rotated or unknown after first boot.
- SSH key management must be explicit and reliable.
- NixOS module system and flake-based deployment are required.

## 4. Solution Plan (Overview)

- Document and enforce a single deploy user with passwordless sudo and trusted-users membership.
- Automate SSH key propagation and validation for deploy user.
- Provide a local-only deployment fallback for initial bootstrap or recovery.
- Write a step-by-step recovery/bootstrapping plan for when remote sudo/ssh is broken.
- Add clear error messages and checks in deployment scripts.
- Review and update documentation as the workflow evolves.

## 1a. User Roles Clarification

- **Rescue (formerly Admin):**
  - Console-only access (physical/KVM), never remote SSH.
  - Used for emergency recovery and initial setup.
  - Password required, no SSH keys.

- **Deploy:**
  - The only user allowed remote SSH access for deployment.
  - SSH key authentication only (no password login).
  - Must always have passwordless sudo and be in trusted-users.

## 5. Solutions for Each Pain Point

### Remote vs Local Deployment Confusion
- **Solution:**
  - Document a clear policy: All deployments must be initiated from a trusted local machine (e.g., orion) using the deploy user and SSH key.
  - Only use remote tools (deploy-rs, nixos-anywhere) when physical access is not possible or for initial bootstrap.
  - Add comments and usage examples to deployment scripts to clarify expected usage.
- **Rationale:**
  - Reduces ambiguity and prevents accidental use of the wrong method.

### SSH and Sudo Permissions Hell
- **Solution:**
  - Enforce passwordless sudo for deploy user via NixOS module, and ensure deploy is always in trusted-users.
  - Rescue user (console only) never has remote SSH or passwordless sudo.
  - Add a deployment check script that verifies sudo and trusted-users before attempting deploy.
- **Rationale:**
  - Prevents chicken-and-egg problems and ensures deploy always works.

### Credential/Key Propagation
- **Solution:**
  - Automate SSH key distribution for deploy user in NixOS config and scripts.
  - Add a script to verify that the correct key is present on the target before deployment.
  - Rescue user never has SSH keys.
- **Rationale:**
  - Ensures deploy user can always connect, and reduces manual key management errors.

### Nix Trusted Users
- **Solution:**
  - Always include deploy in `nix.settings.trusted-users` in the system config.
  - Add a pre-deploy check to verify this before attempting remote activation.
- **Rationale:**
  - Prevents Nix store copy/activation failures.

### Password Management
- **Solution:**
  - Rescue user password is set via secrets and only used for console recovery.
  - Deploy user has no password, only SSH key.
  - Document the process for rotating rescue passwords and updating secrets.
- **Rationale:**
  - Prevents remote brute force and ensures recovery is always possible.

### Error Feedback Loops
- **Solution:**
  - Add more granular checks and early error reporting in deployment scripts.
  - Log all errors and key steps to a central log file for review.
- **Rationale:**
  - Reduces wasted time and makes troubleshooting easier.

### Tooling Frustration
- **Solution:**
  - Document the intended workflow and user roles in the repo.
  - Add clear error messages and usage hints to scripts.
  - Review and update documentation as the workflow evolves.
- **Rationale:**
  - Reduces confusion and frustration for all users (including future you).

## 6. Deployment Recovery & Bootstrapping Plan

### If Remote SSH/Sudo for Deploy User is Broken

1. **Attempt SSH as Deploy User**
   - Try to connect: `ssh deploy@<host>`
   - If connection or sudo fails, proceed to next step.

2. **Access Console (Physical/KVM/Serial)**
   - Use rescue user (console-only): `login: rescue`
   - Password is set via secrets (rotate as needed).

3. **Gain Root Access**
   - Run: `sudo -i` (as rescue)
   - If sudo fails, reboot into recovery/initramfs or use a live ISO.

4. **Fix Deploy User Sudo/Trusted-Users**
   - Edit `/etc/nixos/configuration.nix` or appropriate flake/module:
     - Ensure deploy user is present, has correct SSH key, and:
       - `security.sudo.extraRules` grants passwordless sudo to deploy
       - `nix.settings.trusted-users` includes deploy
   - Rebuild system:
     - `nixos-rebuild switch` (legacy)
     - Or activate new system profile if using flakes

5. **Test Deploy User**
   - SSH in as deploy: `ssh deploy@<host>`
   - Run: `sudo -n true` to confirm passwordless sudo
   - Run: `nix copy` or `deploy-rs` to confirm trusted-users

6. **Remove Console Access if Needed**
   - Ensure rescue user is only available via physical console/KVM
   - Remove any temporary SSH keys or sudoers entries used for recovery

### Prevention Strategies
- Always test deploy user SSH and sudo after any config change.
- Automate checks in deployment scripts.
- Keep rescue password rotated and secure.
- Document any manual recovery steps taken for future reference.

---

See next sections for detailed recovery plan and documentation updates.
