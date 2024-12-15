{
  pkgs,
  username,
  host,
  inputs,
  ...
}:
let
  inherit (import ./variables.nix) gitUsername gitEmail;
in
{
  # Home Manager Settings
  home.username      = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion  = "24.11";

  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  home.file = {
    ".gitconfig".source      = ../../config/.gitconfig;
    "hypr/mocha.conf".source = ../../config/hypr/mocha.conf;
  };

  wayland.windowManager.hyprland = {
    enable      = true;
    # plugins   = [];
    extraConfig = (import ../../config/hypr/hyprland.nix);
  };

  # Install & Configure Git
  programs = {
    home-manager.enable = true;
    rofi.enable         = true;

    btop = {
      enable            = true;
      settings.vim_keys = true;
    };

    kitty = {
      enable      = true;
      package     = pkgs.kitty;
      extraConfig = (import ../../config/kitty/kitty.nix);
    };

    hyprlock = {
      enable      = true;
      extraConfig = (import ../../config/hypr/hyprlock.nix { inherit username; });
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
            timeout    = 60;
            on-timeout = "hyprlock";
          }
          # DPMS
          {
            timeout    = 120;
            on-timeout = "hyprctl dispatch dpms off";
            on-resume  = "hyprctl dispatch dpms on";
          }
          # Suspend
          {
              timeout    = 180;
              on-timeout = "systemctl suspend";
          }
        ];
      };
    };
  };

  # Create XDG Dirs
  xdg = {
    userDirs = {
      enable            = true;
      createDirectories = true;
    };
  };

  # Scripts
  home.packages = [
    (import ../../scripts/screenshootin.nix { inherit pkgs; })
  ];
}