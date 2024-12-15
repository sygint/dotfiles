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
  home.username = "${username}";
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";

  imports = [
    inputs.hyprland.homeManagerModules.default
  ];

  home.file = {
    ".gitconfig".source = ../../config/.gitconfig;
  };

  wayland.windowManager.hyprland = {
    enable = true;
    # plugins = [];
    extraConfig = (import ../../config/hypr/hyprland.nix);
  };

  # Install & Configure Git
  programs = {
    home-manager.enable = true;
    rofi.enable = true;

    btop = {
      enable = true;
      settings.vim_keys = true;
    };

    kitty = {
      enable = true;
      package = pkgs.kitty;
      extraConfig =  (import ../../config/kitty/kitty.nix);
    };
  };

  # Create XDG Dirs
  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };

  # Scripts
  home.packages = [
    (import ../../scripts/screenshootin.nix { inherit pkgs; })
  ];
}