{ config, pkgs, inputs, userVars, lib, ... }:
  let
    inherit (userVars) username;
  in
{
  imports = [
    ../modules/home.nix
    # ../modules/home/programs/git.nix
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
      git.enable = true;
      btop.enable = true;
      kitty.enable = true;
      zsh.enable = true;
      hyprland.enable = true;
      hyprpanel.enable = true;
      rofi.enable = true;
      # devenv.enable = true;
    };
  };

  # wayland.windowManager.sway.enable = true;

  # Enable XDG user directories
  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      desktop = "$HOME/Desktop";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
    };
  };

  programs.home-manager.enable = true;
}
