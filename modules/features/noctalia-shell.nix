{
  config,
  lib,
  inputs,
  pkgs,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.features.noctalia-shell;
in
{
  options.modules.features.noctalia-shell = {
    enable = mkEnableOption "Noctalia Shell - Minimal Quickshell-based desktop shell for Wayland";
  };

  config = mkIf cfg.enable {
    home-manager.sharedModules = [
      (
        { config, ... }:
        let
          inherit (config.lib.file) mkOutOfStoreSymlink;
          # Use the actual filesystem path, NOT inputs.dotfiles.outPath (which
          # resolves to a read-only nix store copy). The whole point of
          # mkOutOfStoreSymlink is to create a symlink to the real mutable file
          # so noctalia can write runtime state back to it.
          configNoctaliaDir = "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/noctalia";
        in
        {
          programs.noctalia-shell = {
            enable = true;
            package = inputs.noctalia-shell.packages.${pkgs.stdenv.hostPlatform.system}.default;
            systemd.enable = true;
            # Don't set settings here — we manage settings.json as a mutable
            # dotfile so noctalia can persist runtime state (settingsVersion,
            # WiFi toggle, user prefs from the GUI, etc). The upstream HM
            # module would create a read-only nix store symlink, which breaks
            # noctalia's ability to write back to the file.
          };

          # Symlink settings and colors to versioned dotfiles in our repo.
          # Noctalia writes runtime state back to settings.json (settingsVersion,
          # wifiEnabled, widget config, etc), and changes show up as git diffs
          # we can review and commit as we see fit.
          # Colors were previously injected by Stylix's noctalia target (catppuccin-mocha
          # base16 scheme) — now baked directly into the dotfile since we disabled
          # that target to avoid the read-only store symlink conflict.
          xdg.configFile = {
            "noctalia/settings.json" = {
              source = mkOutOfStoreSymlink "${configNoctaliaDir}/settings.json";
              force = true;
            };
            "noctalia/colors.json" = {
              source = mkOutOfStoreSymlink "${configNoctaliaDir}/colors.json";
              force = true;
            };
          };
        }
      )
    ];
  };
}
