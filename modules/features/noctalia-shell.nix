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
    home-manager.sharedModules = [
      (
        { config, ... }:
        let
          inherit (config.lib.file) mkOutOfStoreSymlink;
          configNoctaliaDir = "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/noctalia";
        in
        {
          programs.noctalia-shell = {
            enable = true;
            package = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
            systemd.enable = true;
          };

          xdg.configFile = {
            "noctalia/settings.json" = {
              source = mkOutOfStoreSymlink "${configNoctaliaDir}/settings.json";
              force = true;
            };
            "noctalia/colors.json" = {
              source = mkOutOfStoreSymlink "${configNoctaliaDir}/colors.json";
              force = true;
            };
          };
        }
      )
    ];
  };
}
