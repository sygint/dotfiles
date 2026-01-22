{ userVars, ... }:
let
  inherit (userVars) username;
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
  # Core utilities now managed by unified features modules in system configs

  programs = {
    home-manager.enable = true;
  };
}
