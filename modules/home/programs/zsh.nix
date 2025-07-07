{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.settings.programs.zsh;
in {
  options.settings.programs.zsh.enable = mkEnableOption "Zsh shell with live-updating configuration";

  config = mkIf cfg.enable {
    # Enable zsh with Home Manager but minimal configuration
    programs.zsh = {
      enable = true;
      # Disable built-in config generation - we'll manage dotfiles directly
      enableCompletion = false;
      autosuggestion.enable = false;
      syntaxHighlighting.enable = false;
      
      # Minimal zsh configuration to set ZDOTDIR
      initContent = ''
        # ZDOTDIR is set via .zshenv which points to our managed config
      '';
    };

    # Install required packages
    home.packages = with pkgs; [
      starship      # prompt
      eza          # better ls
      fzf          # fuzzy finder
      antidote     # zsh plugin manager
    ];

    # Link our live-updating dotfiles
    home.file.".zshenv" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/zshenv";
      force = true;
    };

    home.file.".config/zsh/.zshrc" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/zsh/zshrc";
      force = true;
    };

    home.file.".config/zsh/plugins.txt" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/zsh/plugins.txt";
      force = true;
    };

    home.file.".config/zsh/plugins.zsh" = {
      source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/zsh/plugins.zsh";
      force = true;
    };
  };
}
