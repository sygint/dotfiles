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
    "hypr/mocha.conf".source = ../../config/hypr/mocha.conf.nix;
    wallpapers = {
      source = ../../config/wallpapers;
      recursive = true;
    };
  };

  wayland.windowManager = {
    hyprland = {
      enable      = true;
      # plugins   = [];
      extraConfig = (import ../../config/hypr/hyprland.conf.nix);
    };

    sway.enable = true;
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
      extraConfig = (import ../../config/hypr/hyprlock.conf.nix { inherit username; });
    };

    chromium = {
      enable = true;
      package = pkgs.brave;
      extensions = [
        "nngceckbapebfimnlniiiahkandclblb" # Bitwarden
        # "ldpochfccmkkmhdbclfhpagapcfdljkj" # Decentraleyes
        "ikclbgejgcbdlhjmckecmdljlpbhmbmf" # HTTPS Everywhere
        # "oboonakemofpalcgghocfoadofidjkkk" # KeePassXC-Browser
        # "fploionmjgeclbkemipmkogoaohcdbig" # Page Load time
        "pkehgijcmpdhfbdbbnkijodmdjhbjlgp" # Privacy Badger        
        # "hjdoplcnndgiblooccencgcggcoihigg" # Terms of Service; Didn’t Read
      ];
    };

    vscode = {
      enable = true;
      package = pkgs.vscodium;
      userSettings = {
        "editor.minimap.enabled" = false;
      };
      extensions = with pkgs.vscode-extensions; [
        # themes
        dracula-theme.theme-dracula

        # syntax
        jnoortheen.nix-ide
        bbenoist.nix
        # vscodevim.vim
        yzhang.markdown-all-in-one

      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
        {
          name = "gitstash";
          publisher = "arturock";
          version = "5.2.0";
          sha256 = "IVWb4tXD+5YbqJv4Ajp0c3UvYdMzh83NlyiYpndclEY=";
        }
      ];
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
  };

  # Scripts
  home.packages = [
    (import ../../scripts/screenshootin.nix { inherit pkgs; })
  ];
}
