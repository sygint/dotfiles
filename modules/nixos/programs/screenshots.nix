{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.screenshots;
in {
  options.settings.programs.screenshots = {
    enable = mkEnableOption "Screenshot helpers";
  };

  # home.packages = with pkgs; mkIf cfg.enable [
  #   (import ../../../scripts/screenshootin.nix { inherit pkgs; })
  # ];

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      grim
      slurp
      swappy
    ];
  };
}