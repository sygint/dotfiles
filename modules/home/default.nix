{ config, userVars, ... }:
let
  inherit (userVars) username;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  configRoot = "/home/${username}/.config/nixos";
in
{
  # Base Home Manager Settings - common for all users on all systems
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";

    # Desktop-specific: wallpapers symlink (live-updating, no rebuild needed)
    file.wallpapers.source = mkOutOfStoreSymlink "${configRoot}/wallpapers";
  };

  # Enable home-manager to manage itself
  programs.home-manager.enable = true;
}
