{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.features.gpu-fan-control;
in
{
  options.modules.features.gpu-fan-control = {
    enable = mkEnableOption "GPU fan control via nvidia-settings (requires Xvfb)";
    speed = mkOption {
      type = types.int;
      default = 50;
      description = "Fan speed percentage (0-100)";
    };
  };

  config = mkIf cfg {
    services.xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };

    services.xvfb = {
      enable = true;
      display = ":0";
      screen = "1920x1080x24";
    };

    systemd.services.gpu-fan-control = {
      description = "NVIDIA GPU fan control via nvidia-settings";
      after = [ "xvfb.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.xorg.xrandr}/bin/xrandr --display :0 || true
          ${pkgs.xorg.nvidia_x11}/bin/nvidia-settings -a "GPUFanControlState=1" -a "FanSpeedPWM=${toString cfg.speed}"
        '';
      };
    };
  };
}
