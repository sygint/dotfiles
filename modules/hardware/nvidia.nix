# NVIDIA GPU — driver, modprobe, persistenced, CUDA toolkit, fan control
# Self-contained hardware module: everything about the physical GPU
{ config, lib, pkgs, ... }:

let
  cfg = config.modules.hardware.nvidia;
in
{
  options.modules.hardware.nvidia = {
    enable = lib.mkEnableOption "NVIDIA GPU driver and infrastructure";
    fanControl = {
      enable = lib.mkEnableOption "GPU fan control via nvidia-settings (for AIO coolers on headless machines)";
      speed = lib.mkOption {
        type = lib.types.int;
        default = 50;
        description = "GPU fan speed percentage when fan control is enabled";
      };
    };
  };

  config = lib.mkIf cfg.enable {
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

    # Xvfb + GPU fan control (headless nvidia-settings)
    systemd.services.xvfb = lib.mkIf cfg.fanControl.enable {
      description = "Xvfb virtual framebuffer for headless NVIDIA settings";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        RemainAfterExit = true;
        ExecStart = "${pkgs.xvfb}/bin/Xvfb :0 -screen 0 1920x1080x24";
        ExecStop = "${pkgs.coreutils}/bin/kill $MAINPID";
      };
    };

    systemd.services.gpu-fan-control = lib.mkIf cfg.fanControl.enable {
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
            /run/current-system/sw/bin/nvidia-settings -a "GPUFanControlState=1" -a "[fan:0]/GPUTargetFanSpeed=${toString cfg.fanControl.speed}" || true
          ''
        );
      };
    };

    environment.systemPackages = with pkgs; [
      nvtopPackages.full
      cudaPackages.cudatoolkit
    ];
  };
}
