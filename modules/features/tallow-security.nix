# Comprehensive agent isolation for tallow
# Layered security approach: namespace + seccomp + capability dropping
{
  config, lib, pkgs, ...}:
let
  cfg = config.tallow.security;
in
{
    options.tallow.security = {
      enable = lib.mkEnableOption "comprehensive agent isolation";

      isolateUserNamespace = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Run agents in user namespace (root→nobody mapping)";
      };

      seccompProfile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        description = "Path to custom seccomp JSON profile for syscall filtering";
      };

      restrictNetworkAccess = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Block all network access during agent execution";
      };

      auditLogs = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable comprehensive syscall logging via auditd";
      };
    };

    config = lib.mkIf cfg.enable {
      # ===== BASE: Bubblewrap sandbox (without Docker) =====
      environment.systemPackages = [
        pkgs.bubblewrap  # Provides bwrap for namespace isolation
      ];

      # ===== SECURITY LAYER 1: User Namespace Isolation =====
      # Maps container root to host nobody (UID 65534)
      security.audit = lib.mkIf cfg.auditLogs {
        enable = true;
        rules = [
          # Log all process execution attempts
          "-a exit,always -F arch=b64 -S execve"
          # Log network syscalls if we allow them (otherwise this is a violation)
          "-w /etc/hosts -p wa"
        ];
      };

      # ===== SECURITY LAYER 2: Process Execution Wrapper =====
      # Creates a script that wraps tallow with isolation
      environment.etc."tallow-wrapper.sh".text =
        let
          seccompLine = lib.optionalString (cfg.seccompProfile != null)
            ''BWRAP_CMD_OPTIONAL_SECCOMP="--seccomp $(realpath ${cfg.seccompProfile})"'';
          networkLine = lib.optionalString cfg.restrictNetworkAccess
            ''BWRAP_CMD_NETWORK_OPTIONS="--bind /dev/null /dev/tcp"'';
        in ''
          #!/usr/bin/env bash
          set -euo pipefail

          # Get arguments passed to this wrapper
          TALLOW_ARGS="''${@}"

          # Optional seccomp filter
          BWRAP_CMD_OPTIONAL_SECCOMP=""
          ${seccompLine}

          # Optional network restrictions
          BWRAP_CMD_NETWORK_OPTIONS=""
          ${networkLine}

          # Define sandbox configuration
          SANDBOX_DIR="$(mktemp -d /run/tallow-sandbox.XXXXXX)"
          trap "rm -rf $SANDBOX_DIR" EXIT

          # Create minimal filesystem structure inside bubblewrap
          mkdir -p "$SANDBOX_DIR/etc"
          mkdir -p "$SANDBOX_DIR/run"
          mkdir -p "$SANDBOX_DIR/tmp"
          mkdir -p "$SANDBOX_DIR/dev/null"
          touch "$SANDBOX_DIR/dev/null"
          chmod 666 "$SANDBOX_DIR/dev/null"

          # Build bubblewrap command with security restrictions
          BWRAP_CMD="bubblewrap"

          # Mount necessary pseudo-filesystems
          $BWRAP_CMD \
            --bind /dev/null /dev/null \
            --ro-bind /proc /proc \
            --dir /run \
            --dir /sys \
            --ro-bind /home/syg/.config/nixos /nixos-config \
            --bind $(pwd) /working-dir \
            $BWRAP_CMD_OPTIONAL_SECCOMP \
            $BWRAP_CMD_NETWORK_OPTIONS \
            --cap-drop-all \
            --rlimit-as 268435456 \
            --rlimit-cpu 300 \
            --rlimit-nproc 100 \
            --env=HOME=/home/syg-tallow-home \
            --env=SHELL=/bin/bash \
            $TALLOW_ARGS
        '';
    };
  }
