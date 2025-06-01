{ config, pkgs, inputs, userVars, ... }:
  let
    inherit (userVars) username gitUsername gitEmail;
  in
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
      source = ../wallpapers;
      recursive = true;
    };

    packages = [
      (import ../scripts/screenshootin.nix { inherit pkgs; })
    ];
  };

  settings = {
    programs = {
      # Desktop
      brave.enable = true;
      librewolf.enable = true;
      vscode.enable = true;
    };

    windowManagers.hyprland.enable = true;

    # hypr suite
    services.hypridle.enable = true;
  };

  wayland.windowManager.sway.enable = true;

  # Install & Configure Git
  programs = {
    starship.enable = true;
    home-manager.enable = true;
    rofi.enable         = true;
  };
}
