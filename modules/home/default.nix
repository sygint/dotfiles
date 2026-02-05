{ userVars, ... }:
let
  inherit (userVars) username;
  # Get the actual system user from environment or fall back to variables
  actualUser = if (builtins.getEnv "USER") != "" then (builtins.getEnv "USER") else username;
in
{
  # Base Home Manager Settings - common for all users on all systems
  home = {
    username = actualUser;
    homeDirectory = "/home/${actualUser}";
    stateVersion = "24.11";

    # Desktop-specific: wallpapers symlink
    # Only applies to desktop systems; server systems ignore this
    file.wallpapers = {
      source = ../../wallpapers;
      recursive = true;
    };
  };

  # Enable home-manager to manage itself
  programs.home-manager.enable = true;
}
