{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.swayidle;
in
{
  options.modules.features.swayidle = {
    enable = mkEnableOption "Swayidle idle daemon for Wayland compositors (niri, sway, etc.)";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      swayidle
    ];

    home-manager.sharedModules = [
      (
        {
          config,
          pkgs,
          userVars,
          ...
        }:
        let
          configRoot = "/home/${userVars.username}/.config/nixos";
          configscriptsDir = "${configRoot}/scripts";
        in
        {
          services.swayidle = {
            enable = true;

            timeouts = [
              # Dim the screen
              {
                timeout = 150;
                command = "brightnessctl -s set 10";
                resumeCommand = "brightnessctl -r";
              }

              # Screenlock
              {
                timeout = 300;
                command = "noctalia-shell ipc call lockScreen lock";
              }

              # DPMS - lock-aware monitor control
              {
                timeout = 600;
                command = "${configscriptsDir}/power/dpms-off-if-locked.sh";
                resumeCommand = "niri msg action power-on-monitors && brightnessctl -r";
              }
            ];

            events = {
              "before-sleep" = "noctalia-shell ipc call lockScreen lock";
            };
          };
        }
      )
    ];
  };
}
