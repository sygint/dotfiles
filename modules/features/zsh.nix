{
  config,
  lib,
  pkgs,
  inputs,
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

          dotfilesDir = "${inputs.dotfiles.outPath}";
          configZshDir = "${dotfilesDir}/.config/zsh";

          # Compositor selection for .zlogin auto-start
          # Defaults to Hyprland for backward compatibility
          compositor = userVars.compositor or "Hyprland";

          # Process .zlogin template with compositor substitution
          zloginTemplate = builtins.readFile "${dotfilesDir}/.zlogin";
          zloginProcessed = pkgs.writeText "zlogin" (
            lib.replaceStrings [ "@compositor@" ] [ compositor ] zloginTemplate
          );
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
            # .zlogin is a processed template (compositor substitution)
            # Must be in ZDOTDIR (.config/zsh) since .zprofile sets ZDOTDIR there
            ".config/zsh/.zlogin" = {
              source = zloginProcessed;
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
