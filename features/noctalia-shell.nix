{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.noctalia-shell;
in
{
  options.modules.features.noctalia-shell = {
    enable = mkEnableOption "Noctalia Shell - Minimal Quickshell-based desktop shell for Wayland";
  };

  config = mkIf cfg.enable {
    # Home-manager configuration
    home-manager.sharedModules = [
      {
        programs.noctalia-shell = {
          enable = true;
          package = inputs.noctalia-shell.packages.${pkgs.system}.default;
          systemd.enable = true;
        };
      }
    ];
  };
}
