{ pkgs, ... }:
{
  imports = [
    ../../../modules/home/base-desktop
    ../../../modules/home.nix
    ./extra-programs.nix
  ];

  home.packages = with pkgs; [
    rofi
  ];

  modules.programs = {
    hyprland = {
      enable = true;
      packages.enable = true;
    };

    hyprpanel.enable = true;        # Enable HyprPanel
    waybar.enable = false;          # Disable Waybar
    hypridle.enable = true;         # Enable Hypridle idle daemon

    zsh.enable = true;              # Enable Zsh shell with starship
    screenshots.enable = true;
    brave.enable = true;
    librewolf.enable = true;
    vscode.enable = true;
    archiver.enable = true;         # Enable archive management with Nemo integration

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
