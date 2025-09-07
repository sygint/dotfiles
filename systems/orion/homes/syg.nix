{ pkgs, ... }:
{
  imports = [
    ../../../modules/home/base-desktop
    ../../../modules/home.nix
  ];

  home.packages = with pkgs; [
    rofi-wayland
  ];

  modules.programs = {
    hyprland = {
      enable = true;
      packages.enable = true;
    };

    screenshots.enable = true;
    brave.enable = true;
    librewolf.enable = true;
    vscode.enable = true;

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
