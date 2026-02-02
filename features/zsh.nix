{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.modules.features.zsh;
in
{
  options.modules.features.zsh = {
    enable = mkEnableOption "Zsh shell with starship, eza, fzf, and antidote";
  };

  config = mkIf cfg.enable {
    # System-level configuration
    programs.zsh.enable = true;

    environment.systemPackages = with pkgs; [
      zsh
    ];

    # Home-manager configuration
    home-manager.sharedModules = [
      (
        {
          config,
          pkgs,
          userVars,
          ...
        }:
        let
          inherit (config.lib.file) mkOutOfStoreSymlink;

          configRoot = "/home/${userVars.username}/.config/nixos";
          dotfilesDir = "${configRoot}/dotfiles";
          configZshDir = "${dotfilesDir}/.config/zsh";
        in
        {
          # Install zsh packages for the user
          home.packages = with pkgs; [
            starship # prompt
            eza # better ls
            fzf # fuzzy finder
            antidote # zsh plugin manager
            bat # better cat (used in fzf previews)
            zoxide # better cd
            fd # better find (used by fzf)
          ];

          # Link live-updating dotfiles
          home.file = {
            ".zshenv" = {
              source = mkOutOfStoreSymlink "${dotfilesDir}/zshenv";
              force = true;
            };
            ".zlogin" = {
              source = mkOutOfStoreSymlink "${dotfilesDir}/.zlogin";
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
        }
      )
    ];
  };
}
