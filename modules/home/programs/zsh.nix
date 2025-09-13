{ config
, lib
, options
, pkgs
, userVars
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  inherit (config.lib.file) mkOutOfStoreSymlink;

  configRoot = "/home/${userVars.username}/.config/nixos";
  dotfilesDir = "${configRoot}/dotfiles";
  configZshDir = "${dotfilesDir}/.config/zsh";
  cfg = config.modules.programs.zsh;
in
{
  options.modules.programs.zsh.enable = mkEnableOption "Zsh shell with live-updating configuration";

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
        source = mkOutOfStoreSymlink "${dotfilesDir}/zshenv";
        force = true;
      };
      ".config/zsh/.zshrc" = {
        source = mkOutOfStoreSymlink "${configZshDir}/zshrc";
        force = true;
      };
      ".config/zsh/plugins.txt" = {
        source = mkOutOfStoreSymlink "${configZshDir}/plugins.txt";
        force = true;
      };
      ".config/zsh/plugins.zsh" = {
        source = mkOutOfStoreSymlink "${configZshDir}/plugins.zsh";
        force = true;
      };
    };
  };
}
