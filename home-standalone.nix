{ config, pkgs, inputs ? {}, userVars ? {}, lib, ... }:
let
  # Use userVars if available, otherwise use defaults
  username = if userVars ? username then userVars.username else "syg";
  gitUsername = if userVars ? gitUsername then userVars.gitUsername else "Sygint";
  gitEmail = if userVars ? gitEmail then userVars.gitEmail else "sygint@users.noreply.github.com";
in
{
  # Import only the specific modules we need
  imports = [
    ./modules/home/programs/brave.nix
    ./modules/home/programs/librewolf.nix
    ./modules/home/programs/vscode.nix
  ];

  # Home Manager Settings
  home = {
    username      = username;
    homeDirectory = "/home/${username}";
    stateVersion  = "24.11";

    file.wallpapers = {
      source = ./wallpapers;
      recursive = true;
    };
  };

  # Allow unfree packages in standalone mode
  nixpkgs.config.allowUnfree = true;

  # Custom settings namespace
  settings = {
    programs = {
      # Desktop
      brave.enable = true;
      librewolf.enable = true;
      vscode.enable = true;
    };
  };

  # Enable Sway window manager
  wayland.windowManager.sway.enable = true;

  # Install & Configure programs
  programs = {
    home-manager.enable = true;
    rofi.enable = true;
    
    # Git configuration
    git = {
      enable = true;
      userName = gitUsername;
      userEmail = gitEmail;
    };
  };
}
