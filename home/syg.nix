{ config, pkgs, inputs, username, gitUsername, gitEmail, browser, terminal, keyboardLayout, menu, ... }:

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

  settings = {
    programs = {
      # CLI
      btop.enable  = true;
      git = {
        enable = true;

        userName  = "${gitUsername}";
        userEmail = "${gitEmail}";
      };

      # Desktop
      brave.enable = true;
      firefox.enable = true;
      kitty.enable = true;
      vscode.enable = true;
    };

    windowManagers.hyprland.enable = true;
  };

  wayland.windowManager.sway.enable = true;

  # Install & Configure Git
  programs = {
    home-manager.enable = true;
    rofi.enable         = true;
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
