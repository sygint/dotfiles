{ config
, lib
, options
, pkgs
, userVars
, userConfig ? null
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;

  configRoot = "/home/${userVars.username}/.config/nixos";
  configHyprpanelDir = "${configRoot}/dotfiles/dotfiles/.config/dotfiles/.config/hyprpanel";
  cfg = config.modules.programs.hyprpanel;
in
{
  options.modules.programs.hyprpanel.enable = mkEnableOption "HyprPanel - A Bar/Panel for Hyprland";

  config = mkIf cfg.enable {
    # Install hyprpanel from nixpkgs
    home.packages = with pkgs; [
      hyprpanel
    ];

    # Link hyprpanel configuration files with live updates
    # Note: JSON files are processed by Home Manager but will update on rebuild
    xdg = {
      configFile = {
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
    };
  };
}
