{ userVars, ... }:
let
  inherit (userVars.user) username;
  # Get the actual system user from environment or fall back to variables
  actualUser = if (builtins.getEnv "USER") != "" then (builtins.getEnv "USER") else username;
in
{
  imports = [
    # Import the main home modules barrel file
    ../../home.nix
  ];

  # Base Home Manager Settings - common for all users on all systems
  home = {
    username = actualUser;
    homeDirectory = "/home/${actualUser}";
    stateVersion = "24.11";

    file.wallpapers = {
      source = ../../../wallpapers;
      recursive = true;
    };
  };

  # Base programs that every user should have regardless of system
  settings = {
    programs = {
      # Core utilities - essential for everyone
      btop.enable = true;
      kitty.enable = true;
      zsh.enable = true;
      git.enable = true;
    };
  };

  programs = {
    home-manager.enable = true;
  };
}
