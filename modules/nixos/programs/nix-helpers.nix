{
  config,
  lib,
  options,
  pkgs,
  userVars,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.nix-helpers;
  inherit (userVars) username;
in {
  options.settings.programs.nix-helpers.enable = mkEnableOption "Nix helpers";

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d";
      flake = "/home/${username}/.config/nixos";
    };

    environment.systemPackages = with pkgs; [
      nix-inspect
      nix-output-monitor
      nvd
    ];

    # environment.sessionVariables = {
    #   FLAKE = "/mount/nixos";
    # };
  };
}