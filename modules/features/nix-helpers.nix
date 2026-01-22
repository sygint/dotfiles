{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.nix-helpers;
in
{
  options.modules.features.nix-helpers.enable = mkEnableOption "Nix helper tools and utilities";

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep-since 7d";
      flake = "/home/${userVars.username}/.config/nixos";
    };

    environment.systemPackages = with pkgs; [
      nh
      nix-inspect
      nix-output-monitor
      nixpkgs-fmt
      nvd
    ];
  };
}
