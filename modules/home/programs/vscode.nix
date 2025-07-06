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
        extensions = with pkgs.vscode-extensions; [
          # themes
          dracula-theme.theme-dracula

          # syntax
          jnoortheen.nix-ide
          bbenoist.nix
          svelte.svelte-vscode
          bradlc.vscode-tailwindcss
          # vscodevim.vim
          yzhang.markdown-all-in-one

          # git
          github.vscode-github-actions
          mhutchie.git-graph

        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "github-local-actions";
            publisher = "sanjulaganepola";
            version = "1.2.5";
            sha256 = "sha256-gc3iOB/ibu4YBRdeyE6nmG72RbAsV0WIhiD8x2HNCfY=";
          }
          {
            name = "shellcheck";
            publisher = "timonwong";
            version = "0.37.7";
            sha256 = "sha256-i8cVY8EcKSxnmWmRWDiARF79pOEcYMc+y+7i4d8EDTo=";
          }
          {
            name = "gitless";
            publisher = "maattdd";
            version = "11.7.2";
            sha256 = "sha256-rYeZNBz6HeZ059ksChGsXbuOao9H5m5lHGXJ4ELs6xc=";
          }
          {
            name = "vscode-kanbn-boards";
            publisher = "samgiz";
            version = "0.14.1";
            sha256 = "sha256-+BIMS5icyEmj1JXKVZmcOfTFI4w/F1zpjbt9ziG7XEk=";
          }
          {
            name = "vscode-versionlens";
            publisher = "pflannery";
            version = "1.16.2";
            sha256 = "sha256-avrq1e+L+2ZCIDBz1WOOHtU9a16VNkDOzrE1ccPnTKg=";
          }
        ];
      };
      home.file.".config/Code/User/settings.json" = lib.mkOutOfStoreSymlink {
        source = ../../dotfiles/dot_config/Code/User/settings.json;
      };
      home.file.".config/git/config" = lib.mkOutOfStoreSymlink {
        source = ../../dotfiles/git/config;
      };
    };
  };
}