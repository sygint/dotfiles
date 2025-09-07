{ pkgs, ... }:
{
  imports = [
    ../../../modules/home/base-desktop
    ../../../modules/home/programs/screenshots.nix
    ../../../modules/home/programs/devenv.nix
    ../../../modules/home/programs/protonmail-bridge.nix
  ];

  home.packages = with pkgs; [
    rofi-wayland
  ];

  settings = {
    programs = {
      # Additional programs for syg
      screenshots.enable = true;
      # Desktop applications
      brave.enable = true;
      librewolf.enable = true;
      vscode.enable = true;
      hyprland.enable = true;
      hyprpanel.enable = true;
    };
  };

  programs = {
    protonmail-bridge = {
      enable = true;
      username = "admin";
      password = "password";
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
}
