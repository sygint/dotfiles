{
  config,
  lib,
  options,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.settings.programs.vscode;
in {
  options.settings.programs.vscode.enable = mkEnableOption "Visual Studio Code code editor";

  config = mkIf cfg.enable {
    programs.vscode = {
      enable = true;
      profiles.default = {
        userSettings = {
          "editor.minimap.enabled" = false;
          "svelte.enable-ts-plugin" = true;
          "diffEditor.renderSideBySide" = false;
          "diffEditor.ignoreTrimWhitespace" = false;
          "editor.tabSize" =  2;
          "editor.indentSize" = "tabSize";
        };
        extensions = with pkgs.vscode-extensions; [
          # themes
          dracula-theme.theme-dracula

          # syntax
          jnoortheen.nix-ide
          bbenoist.nix
          # vscodevim.vim
          yzhang.markdown-all-in-one

        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "gitless";
            publisher = "maattdd";
            version = "11.7.2";
            sha256 = "rYeZNBz6HeZ059ksChGsXbuOao9H5m5lHGXJ4ELs6xc=";
          }
          {
            name = "vscode-kanbn-boards";
            publisher = "samgiz";
            version = "0.14.1";
            sha256 = "+BIMS5icyEmj1JXKVZmcOfTFI4w/F1zpjbt9ziG7XEk=";
          }
          {
            name = "svelte-vscode";
            publisher = "svelte";
            version = "109.5.2";
            sha256 = "y1se0+LY1M+YKCm+gxBsyHLOQU6Xl095xP6z0xpf9mM=";
          }
          {
            name = "vscode-tailwindcss";
            publisher = "bradlc";
            version = "0.14.1";
            sha256 = "eOdltfRP4npYfQKDhGgP2gtc7jrqOv6igWP6DLfJGRw=";
          }
          {
            name = "vscode-versionlens";
            publisher = "pflannery";
            version = "1.16.2";
            sha256 = "avrq1e+L+2ZCIDBz1WOOHtU9a16VNkDOzrE1ccPnTKg=";
          }
        ];
      };
    };
  };
}