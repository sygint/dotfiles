{ config, pkgs, username, host, inputs, ... }:
let
  inherit (import ./variables.nix) gitUsername gitEmail;
in
{
  # Home Manager Settings
  home.username      = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion  = "24.11";

  imports = [
    ../modules/home.nix
    inputs.hyprland.homeManagerModules.default
  ];

  home = {
    file = {
      "hypr/mocha.conf".source = ../config/hypr/mocha.conf.nix;
      wallpapers = {
        source = ../config/wallpapers;
        recursive = true;
      };
    };

    packages = [
      (import ../scripts/screenshootin.nix { inherit pkgs; })
    ];
  };

  settings.programs = {
    # CLI
    btop.enable  = true;
    git = {
      enable = true;

      userName  = "syg";
      userEmail = "sygint@users.noreply.github.com";
    };

    # Desktop
    brave.enable = true;
    firefox.enable = true;
    kitty.enable = true;
    vscode.enable = true;
  };

  wayland.windowManager = {
    hyprland = {
      enable      = true;
      # plugins   = [];
      extraConfig = (import ../config/hypr/hyprland.conf.nix);
    };

    sway.enable = true;
  };

  # Install & Configure Git
  programs = {
    home-manager.enable = true;
    rofi.enable         = true;

    hyprlock = {
      enable      = true;
      extraConfig = (import ../config/hypr/hyprlock.conf.nix { inherit username; });
    };
  };

  services = {
    hypridle = {
      enable   = true;
      settings = {
        general = {
          lock_cmd            = "pidof hyprlock || hyprlock";  # avoid starting multiple hyprlock instances.
          before_sleep_cmd    = "loginctl lock-session";       # lock before suspend.
          after_sleep_cmd     = "hyprctl dispatch dpms on";    # to avoid having to press a key twice to turn on the display.
          ignore_dbus_inhibit = false;
        };

        listener = [
          # Screenlock
          {
            timeout    = 300;
            on-timeout = "hyprlock";
          }
          # DPMS
          {
            timeout    = 600;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on";
          }
          # Suspend
          # {
          #   timeout    = 1200;
          #   on-timeout = "systemctl suspend";
          # }
        ];
      };
    };

    # This doesn't seem to work for some reason
    # xdg-desktop-portal-hyprland.enable = true;
  };

  # Create XDG Dirs
  xdg = {
    userDirs = {
      enable            = true;
      createDirectories = true;
    };

    # configFile."Code/User/settings.json".source =
    #   config.lib.file.mkOutOfStoreSymlink
    #   "${config.home.homeDirectory}/.config/nixos/dotfiles/vscode/settings.json";
  };
}
