# Power Management Module - Suspend, Wake-on-LAN, and Idle Detection
# Enables machines to suspend to RAM and be woken via Wake-on-LAN.
# Optionally auto-suspends after a configurable idle period.
#
# Usage:
#   modules.features.power-management = {
#     enable = true;
#     wakeOnLan.interface = "enp3s0";
#     autoSuspend.enable = true;
#     autoSuspend.idleMinutes = 30;
#   };
{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    mkMerge
    types
    optionalString
    ;

  cfg = config.modules.features.power-management;

  # Idle check script - returns 0 (idle) or 1 (busy)
  idleCheckScript = pkgs.writeShellScript "check-idle" ''
    set -euo pipefail

    # Check for active SSH sessions (excluding our own check)
    ssh_sessions=$(who | grep -c "pts/" || true)
    if [ "$ssh_sessions" -gt 0 ]; then
      echo "Active SSH sessions: $ssh_sessions"
      exit 1
    fi

    # Check system load (busy if 1-min load > threshold)
    load=$(${pkgs.coreutils}/bin/cat /proc/loadavg | ${pkgs.coreutils}/bin/cut -d' ' -f1)
    threshold="${toString cfg.autoSuspend.loadThreshold}"
    if ${pkgs.bc}/bin/bc -l <<< "$load > $threshold" | grep -q 1; then
      echo "System load too high: $load > $threshold"
      exit 1
    fi

    ${optionalString cfg.autoSuspend.gpuAware ''
      # Check NVIDIA GPU utilization
      if command -v nvidia-smi &>/dev/null; then
        gpu_util=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits 2>/dev/null | head -1 || echo "0")
        if [ "''${gpu_util:-0}" -gt "${toString cfg.autoSuspend.gpuThreshold}" ]; then
          echo "GPU busy: ''${gpu_util}% utilization"
          exit 1
        fi

        # Check if any GPU processes are running (inference, training, etc.)
        gpu_procs=$(nvidia-smi --query-compute-apps=pid --format=csv,noheader 2>/dev/null | wc -l || echo "0")
        if [ "$gpu_procs" -gt 0 ]; then
          echo "GPU has $gpu_procs active compute processes"
          exit 1
        fi
      fi
    ''}

    ${optionalString (cfg.autoSuspend.extraIdleCheck != null) ''
      # Custom idle check
      ${cfg.autoSuspend.extraIdleCheck}
    ''}

    echo "System is idle"
    exit 0
  '';

  # Auto-suspend timer script - tracks consecutive idle checks
  autoSuspendScript = pkgs.writeShellScript "auto-suspend" ''
    set -euo pipefail

    STATE_FILE="/run/power-management/idle-count"
    REQUIRED_CHECKS=${toString cfg.autoSuspend.requiredIdleChecks}

    mkdir -p /run/power-management

    if ${idleCheckScript}; then
      # System is idle, increment counter
      current=$(cat "$STATE_FILE" 2>/dev/null || echo "0")
      next=$((current + 1))
      echo "$next" > "$STATE_FILE"
      echo "Idle check $next/$REQUIRED_CHECKS"

      if [ "$next" -ge "$REQUIRED_CHECKS" ]; then
        echo "System idle for $REQUIRED_CHECKS consecutive checks, suspending..."
        echo "0" > "$STATE_FILE"
        ${pkgs.systemd}/bin/systemctl suspend
      fi
    else
      # System is busy, reset counter
      echo "0" > "$STATE_FILE"
    fi
  '';
in
{
  options.modules.features.power-management = {
    enable = mkEnableOption "power management with suspend and Wake-on-LAN";

    wakeOnLan = {
      interface = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Network interface to enable Wake-on-LAN on (e.g., enp3s0)";
      };
    };

    autoSuspend = {
      enable = mkEnableOption "automatic suspend after idle period";

      idleMinutes = mkOption {
        type = types.int;
        default = 30;
        description = "Minutes of idle time before auto-suspend";
      };

      checkIntervalMinutes = mkOption {
        type = types.int;
        default = 5;
        description = "How often to check idle status (minutes)";
      };

      requiredIdleChecks = mkOption {
        type = types.int;
        default = 0;
        description = ''
          Number of consecutive idle checks before suspending.
          Defaults to idleMinutes / checkIntervalMinutes if set to 0.
        '';
      };

      loadThreshold = mkOption {
        type = types.float;
        default = 0.5;
        description = "System load average threshold above which the machine is considered busy";
      };

      gpuAware = mkOption {
        type = types.bool;
        default = false;
        description = "Check NVIDIA GPU utilization before suspending";
      };

      gpuThreshold = mkOption {
        type = types.int;
        default = 5;
        description = "GPU utilization percentage above which the machine is considered busy";
      };

      extraIdleCheck = mkOption {
        type = types.nullOr types.lines;
        default = null;
        description = ''
          Extra shell commands for idle detection. Should exit 1 if the system is busy.
          Has access to standard coreutils.
        '';
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # ===== Core: Allow suspend =====
    {
      # Ensure systemd suspend/resume works
      systemd.targets.suspend.enable = true;

      # Install useful power management tools
      environment.systemPackages = with pkgs; [
        ethtool # For WoL diagnostics
      ];

      # Note: NVIDIA suspend/resume is handled by hardware.nvidia.powerManagement.enable
      # which should be set in the ai-services module (or wherever NVIDIA is configured).
      # No NVIDIA-specific config here to avoid depending on the NVIDIA driver being present.
    }

    # ===== Wake-on-LAN =====
    (mkIf (cfg.wakeOnLan.interface != null) {
      # Persist WoL setting across reboots via a oneshot service
      # ethtool -s <iface> wol g enables magic packet wake
      systemd.services.wol-enable = {
        description = "Enable Wake-on-LAN on ${cfg.wakeOnLan.interface}";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "${pkgs.ethtool}/bin/ethtool -s ${cfg.wakeOnLan.interface} wol g";
        };
      };
    })

    # ===== Auto-suspend on idle =====
    (mkIf cfg.autoSuspend.enable (
      let
        effectiveChecks =
          if cfg.autoSuspend.requiredIdleChecks > 0 then
            cfg.autoSuspend.requiredIdleChecks
          else
            cfg.autoSuspend.idleMinutes / cfg.autoSuspend.checkIntervalMinutes;
      in
      {
        # Override requiredIdleChecks with computed value
        modules.features.power-management.autoSuspend.requiredIdleChecks = lib.mkDefault effectiveChecks;

        # Timer that fires periodically to check idle status
        systemd.timers.auto-suspend = {
          description = "Check system idle status for auto-suspend";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnBootSec = "${toString cfg.autoSuspend.idleMinutes}min";
            OnUnitActiveSec = "${toString cfg.autoSuspend.checkIntervalMinutes}min";
            Persistent = false; # Don't catch up on missed checks after wake
          };
        };

        systemd.services.auto-suspend = {
          description = "Auto-suspend if system is idle";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = autoSuspendScript;
          };
        };

        # Clean up idle counter on resume (so we don't immediately re-suspend)
        systemd.services.auto-suspend-reset = {
          description = "Reset idle counter after resume from suspend";
          after = [ "suspend.target" ];
          wantedBy = [ "suspend.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.coreutils}/bin/rm -f /run/power-management/idle-count";
          };
        };
      }
    ))
  ]);
}
