{ userVars, ... }:
let
  inherit (userVars) username;
in
{
  imports = [
    ../modules/home.nix
    ../modules/home/programs/screenshots.nix
    ../modules/home/programs/devenv.nix
  ];

  # Home Manager Settings
  home = {
    username = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion = "24.11";

    file.wallpapers = {
      source = ../wallpapers;
      recursive = true;
    };
  };

  settings = {
    programs = {
      # utilities
      btop.enable = true;
      kitty.enable = true;
      screenshots.enable = true;
      zsh.enable = true;
      # Desktop
      brave.enable = true;
      librewolf.enable = true;
      vscode.enable = true;
      git.enable = true;
      hyprland.enable = true;
      hyprpanel.enable = true;
    };
  };

  # wayland.windowManager.sway.enable = true;

  # Enable XDG user directories
  # xdg = {
  #   enable = true;
  #   createDirectories = true;
  #   userDirs = {
  #     enable = true;
  #     documents = "Documents";
  #     downloads = "Downloads";
  #     music = "Music";
  #     pictures = "Pictures";
  #     videos = "Videos";
  #   };
  # };

  programs = {
    home-manager.enable = true;
    rofi.enable = true;
  };
}
