{
  config,
  lib,
  options,
  pkgs,
  inputs,
  userVars,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.devenv;
in {
  options.settings.programs.devenv.enable = mkEnableOption "devenv development environment manager";

  config = mkIf cfg.enable {
    # Enable devenv support  
    environment.systemPackages = with pkgs; [
      inputs.devenv.packages."${pkgs.system}".devenv
      cachix  # For caching devenv builds
    ];

    # Enable nix-direnv for better direnv integration with nix
    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };

    # Enable additional development tools
    environment.variables = {
      # Set default shell for devenv
      DEVENV_SHELL = "${pkgs.zsh}/bin/zsh";
    };

    # Enable development-focused services
    services.lorri.enable = true;  # Alternative to nix-direnv for some workflows
  };
}
