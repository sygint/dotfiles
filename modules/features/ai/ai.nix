{ config, lib, pkgs, ... }:

let
  cfg = config.modules.features.ai;
in
{
  options.modules.features.ai = {
    enable = lib.mkEnableOption "AI services namespace (openwebui, ollama, llmster)";

    enableOllmcp = lib.mkEnableOption "Enable ollmcp for MCP tool support (filesystem, git, web search)";
    enableGpuFanControl = lib.mkEnableOption "Enable GPU fan control via nvidia-settings (for AIO coolers)";
    gpuFanSpeed = lib.mkOption {
      type = lib.types.int;
      default = 50;
      description = "GPU fan speed percentage when fan control is enabled";
    };

    # Per-service option groups
    openWebui = {
      enable = lib.mkEnableOption "Enable Open WebUI service";
      host = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0";
        description = "Host address for Open WebUI to bind to";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 8888;
        description = "TCP port for Open WebUI";
      };
    };

    ollama = {
      enable = lib.mkEnableOption "Enable Ollama server";
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Optional Nix package providing ollama binary";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 11434;
        description = "TCP port for Ollama API";
      };
    };

    llmster = {
      enable = lib.mkEnableOption "Enable llmster (LM Studio headless server)";
      package = lib.mkOption {
        type = lib.types.nullOr lib.types.package;
        default = null;
        description = "Nix package that provides the `llmster` executable.";
      };
      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = "Address llmster should bind to (keep local for security)";
      };
      port = lib.mkOption {
        type = lib.types.int;
        default = 1234;
        description = "TCP port for llmster to listen on";
      };
      extraArgs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Additional command-line arguments passed to llmster";
      };
    };
  };

  # Implementation
  config = lib.mkIf cfg.enable {
    # Enable GPU driver userspace libraries (creates /run/opengl-driver/lib)
    hardware.graphics.enable = true;

    services.xserver.videoDrivers = [ "nvidia" ];

    hardware.nvidia = {
      open = true;
      modesetting.enable = true;
      powerManagement.enable = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };

    hardware.nvidia.nvidiaPersistenced = true;

    boot.extraModprobeConfig = ''
      options nvidia NVreg_PreserveVideoMemoryAllocations=1
      options nvidia "coolbits=12"
      options nvidia_uvm uvm_disable_hmm=1
    '';

    # Xvfb and GPU fan services (kept small)
    systemd.services.xvfb = lib.mkIf (config.modules.features.ai.enableGpuFanControl or cfg.enableGpuFanControl) {
      description = "Xvfb virtual framebuffer for headless NVIDIA settings";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = true;
        ExecStart = "${pkgs.xvfb}/bin/Xvfb :0 -screen 0 1920x1080x24";
        ExecStop = "${pkgs.coreutils}/bin/kill $MAINPID";
      };
    };

    systemd.services.gpu-fan-control = lib.mkIf (config.modules.features.ai.enableGpuFanControl or cfg.enableGpuFanControl) {
      description = "NVIDIA GPU fan control via nvidia-settings";
      after = [ "xvfb.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        Environment = "DISPLAY=:0";
        ExecStart = lib.getExe (
          pkgs.writeShellScriptBin "gpu-fan-control" ''
            sleep 2
            /run/current-system/sw/bin/nvidia-settings -a "GPUFanControlState=1" -a "[fan:0]/GPUTargetFanSpeed=${toString cfg.gpuFanSpeed}" || true
          ''
        );
      };
    };

    # Import per-service submodules located in the same directory
    imports = lib.optionals true [ ./services/llmster.nix ./services/openwebui.nix ./services/ollama.nix ./compat.nix ];

    # Firewall and tune
    networking.firewall.allowedTCPPorts = (lib.optionals (cfg.ollama.enable or cfg.enableOllmcp) [ cfg.ollama.port ]) ++ lib.optionals cfg.openWebui.enable [ cfg.openWebui.port ];

    boot.kernel.sysctl = {
      "kernel.shmmax" = 34359738368;
      "kernel.shmall" = 8388608;
      "vm.swappiness" = 10;
    };

    environment.systemPackages = (with pkgs; [ ollama nvtopPackages.full cudaPackages.cudatoolkit ]) ++ lib.optionals cfg.enableOllmcp (with pkgs; [ uv nodejs git (python3.withPackages (ps: with ps; [ ollama ])) ]);
  };
}
