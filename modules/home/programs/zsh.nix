{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;
  cfg = config.settings.programs.zsh;
in
{
  options.settings.programs.zsh.enable = mkEnableOption "Zsh shell with live-updating configuration";

  config = mkIf cfg.enable {
    # Install zsh as a package instead of using programs.zsh to avoid .zshenv conflicts
    home.packages = with pkgs; [
      zsh # zsh shell
      starship # prompt
      eza # better ls
      fzf # fuzzy finder
      antidote # zsh plugin manager
    ];

    home.file = {
      ".zshenv" = {
        source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/zshenv";
        force = true;
      };
      ".config/zsh/.zshrc" = {
        source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/zsh/zshrc";
        force = true;
      };
      ".config/zsh/plugins.txt" = {
        source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/zsh/plugins.txt";
        force = true;
      };
      ".config/zsh/plugins.zsh" = {
        source = mkOutOfStoreSymlink "/home/syg/.config/nixos/dotfiles/.config/zsh/plugins.zsh";
        force = true;
      };
    };
  };
}
