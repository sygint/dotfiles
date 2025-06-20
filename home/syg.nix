{ config, pkgs, inputs, userVars, ... }:
  let
    inherit (userVars) username gitUsername gitEmail;
  in
{
  imports = [
    ../modules/home.nix
  ];

  # Home Manager Settings
  home = {
    username      = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion  = "24.11";

    file.wallpapers = {
      source = ../wallpapers;
      recursive = true;
    };
  };

  settings = {
    programs = {
      # Desktop
      brave.enable = true;
      librewolf.enable = true;
      vscode.enable = true;
    };
  };

  wayland.windowManager.sway.enable = true;

  # Install & Configure Git
  programs = {
    home-manager.enable = true;
    rofi.enable         = true;
  };
}
