{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.hyprpanel;
in
{
  options.modules.features.hyprpanel = {
    enable = mkEnableOption "HyprPanel - A Bar/Panel for Hyprland";
  };

  config = mkIf cfg.enable {
    # Home-manager configuration
    home-manager.sharedModules = [
      (
        {
          config,
          pkgs,
          userVars,
          ...
        }:
        let
          inherit (config.lib.file) mkOutOfStoreSymlink;
          configRoot = "/home/${userVars.username}/.config/nixos";
          configHyprpanelDir = "${configRoot}/dotfiles/.config/hyprpanel";
        in
        {
          # Install hyprpanel from nixpkgs
          home.packages = with pkgs; [
            hyprpanel
          ];

          # Link hyprpanel configuration files with live updates
          xdg.configFile = {
            "hyprpanel/config.json" = {
              source = mkOutOfStoreSymlink "${configHyprpanelDir}/config.json";
              force = true;
            };
            "hyprpanel/modules.json" = {
              source = mkOutOfStoreSymlink "${configHyprpanelDir}/modules.json";
              force = true;
            };
            "hyprpanel/modules.scss" = {
              source = mkOutOfStoreSymlink "${configHyprpanelDir}/modules.scss";
              force = true;
            };
          };
        }
      )
    ];
  };
}
