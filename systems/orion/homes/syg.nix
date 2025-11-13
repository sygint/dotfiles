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
    vscode = {
      enable = true;
      copilotPrompts.enable = true; # Enable curated GitHub Copilot Chat prompts
    };
    archiver.enable = true;         # Enable archive management with Nemo integration

    protonmail-bridge = {
      enable = true;
      username = "admin";
      password = "password";
    };
  };

  # Declarative Flatpak management
  services.flatpak = {
    enable = true;
    packages = [
      "us.zoom.Zoom"
    ];
    update = {
      onActivation = false;  # Don't auto-update on every rebuild
      auto = {
        enable = true;
        onCalendar = "weekly";  # Auto-update weekly
      };
    };
  };

    # Add Flatpak directories to XDG_DATA_DIRS so apps appear in Rofi
  home.sessionVariables = {
    XDG_DATA_DIRS = "$XDG_DATA_DIRS:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
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
