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
  };

  # Base programs that every user should have regardless of system
  modules = {
    programs = {
      # Core utilities - essential for everyone
      btop.enable = true;
      zsh.enable = true;
      git.enable = true;
    };
  };

  programs = {
    home-manager.enable = true;
  };
}
