# PRD: Leantime Container Deployment Diagnosis (nexus)

## Problem Statement
Leantime containers (`leantime` and `leantime-db`) are not being created or started on the `nexus` host after NixOS configuration deployment. The service is unavailable and `podman ps -a` shows no containers.

## Current Configuration
- NixOS config: `/systems/nexus/default.nix`
- Container backend: Podman
- Container definitions under `virtualisation.oci-containers.containers`
- Secrets: `nexus/leantime_db_env`, `nexus/leantime_app_env` (SOPS-managed)
- Data directories: `/var/lib/leantime/*` (created via `systemd.tmpfiles.rules`)

## Hypotheses & Checks
1. **Secrets missing or unreadable**
   - Check existence and permissions of `/run/secrets/nexus/leantime_db_env` and `/run/secrets/nexus/leantime_app_env` on `nexus`.
2. **Podman backend misconfigured**
   - Validate Podman service is running and enabled.
3. **NixOS module/flake evaluation errors**
   - Review activation logs for errors during container creation.
4. **Directory permissions or existence issues**
   - Ensure `/var/lib/leantime/*` directories exist and have correct ownership/permissions.
5. **Container image pull or network issues**
   - Check for image pull errors in activation logs.

## Next Steps
- Run diagnostics for each hypothesis above.
- Collect and analyze activation logs and error messages.
- If a root cause is found, update config or environment and redeploy.
- If not, escalate to deeper NixOS or Podman debugging.

## Remediation Plan
- Fix any missing secrets, directory, or config issues.
- Ensure Podman is running and enabled.
- Redeploy and verify container creation.
- Document findings and update this PRD with resolution steps.

---
*Created by GitHub Copilot on 2025-12-04 for Leantime container troubleshooting.*
