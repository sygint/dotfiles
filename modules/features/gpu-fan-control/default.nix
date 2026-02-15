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
    optionalString
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
    targetTemp = mkOption {
      type = types.int;
      default = 55;
      description = "Target GPU temperature for dynamic fan control";
    };
  };

  config = mkIf cfg.enable {
    services.xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
    };

    systemd.services.xvfb = {
      description = "Xvfb virtual framebuffer for headless NVIDIA settings";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.xvfb}/bin/Xvfb :0 -screen 0 1920x1080x24";
        ExecStop = "${pkgs.lsof}/bin/lsof -t :0 | xargs -r kill";
      };
    };

    systemd.services.gpu-fan-control = {
      description = "NVIDIA GPU fan control via nvidia-settings";
      after = [ "xvfb.service" ];
      wantedBy = [ "multi-user.target" };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = ''
          ${pkgs.xorg.xrandr}/bin/xrandr --display :0 || true
          nvidia-settings -a "GPUFanControlState=1" -a "FanSpeedPWM=${toString cfg.speed}"
        '';
      };
    };
  };
}
