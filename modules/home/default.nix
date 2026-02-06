{ userVars, ... }:
let
  inherit (userVars) username;
in
{
  # Base Home Manager Settings - common for all users on all systems
  home = {
    username = username;
    homeDirectory = "/home/${username}";
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
