{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.vscode;
in
{
  options.modules.programs.vscode.enable = mkEnableOption "Visual Studio Code code editor";

  config = mkIf cfg.enable {
    # Build VS Code with selected extensions included. Installing extension
    # packages into `home.packages` doesn't make the editor load them; use
    # `vscode-with-extensions` (or override `vscode` with `vscodeExtensions`) so
    # the resulting derivation bundles the extensions for the editor to find.
    home.packages = [
      (pkgs.vscode-with-extensions.override {
        vscodeExtensions = with pkgs.vscode-extensions; [
          # themes
          dracula-theme.theme-dracula

          # syntax
          jnoortheen.nix-ide
          bbenoist.nix
          svelte.svelte-vscode
          bradlc.vscode-tailwindcss
          yzhang.markdown-all-in-one

          timonwong.shellcheck

          # git
          # maattdd.gitless
          mhutchie.git-graph

          # copilot
          github.copilot
          github.copilot-chat
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "github-local-actions";
            publisher = "sanjulaganepola";
            version = "1.2.5";
            sha256 = "sha256-gc3iOB/ibu4YBRdeyE6nmG72RbAsV0WIhiD8x2HNCfY=";
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
      })
    ];

    # Manual extension installation script
    # home.activation.installVSCodeExtensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    #   $DRY_RUN_CMD ${pkgs.vscode}/bin/code --install-extension ms-vscode.vscode-github-actions || true
    #   # Add more extensions as needed
    # '';

    # Fix the settings.json symlink after everything else runs
    # home.activation.fixVSCodeSettings = lib.hm.dag.entryAfter ["linkGeneration"] ''
    #   $DRY_RUN_CMD rm -f /home/syg/.config/Code/User/settings.json
    #   $DRY_RUN_CMD ln -sf /home/syg/.config/nixos/dotfiles/.config/Code/User/settings.json /home/syg/.config/Code/User/settings.json
    # '';
  };
}
