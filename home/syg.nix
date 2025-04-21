{ config, pkgs, inputs, username, gitUsername, gitEmail, browser, terminal, keyboardLayout, menu, ... }:

{
  imports = [
    ../modules/home.nix
    inputs.hyprland.homeManagerModules.default
  ];

  # Home Manager Settings
  home = {
    username      = "${username}";
    homeDirectory = "/home/${username}";
    stateVersion  = "24.11";

    file.wallpapers = {
      source = ../config/wallpapers;
      recursive = true;
    };

    packages = [
      (import ../scripts/screenshootin.nix { inherit pkgs; })
    ];
  };

  settings = {
    programs = {
      zsh = {
        enable = true;
      };

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
    starship.enable = true;
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
