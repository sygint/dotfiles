{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.features.vscode;
in
{
  options.modules.features.vscode = {
    enable = mkEnableOption "Visual Studio Code code editor";

    variant = mkOption {
      type = types.enum [
        "standard"
        "fhs"
      ];
      default = "fhs";
      description = ''
        VS Code variant to use:
        - standard: Declarative extension management
        - fhs: FHS environment for imperative extension management
      '';
    };

    copilotPrompts.enable = mkEnableOption "VS Code Copilot Chat prompts and instructions";
  };

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} =
      { config, ... }:
      {
        home.packages =
          if cfg.variant == "fhs" then
            [ pkgs.vscode-fhs ]
          else
            [
              (pkgs.vscode-with-extensions.override {
                vscodeExtensions =
                  with pkgs.vscode-extensions;
                  [
                    # themes
                    dracula-theme.theme-dracula

                    # syntax
                    jnoortheen.nix-ide
                    bbenoist.nix
                    astro-build.astro-vscode
                    svelte.svelte-vscode
                    bradlc.vscode-tailwindcss
                    yzhang.markdown-all-in-one

                    # productivity
                    streetsidesoftware.code-spell-checker
                    usernamehw.errorlens
                    dbaeumer.vscode-eslint
                    alefragnani.project-manager
                    ryu1kn.partial-diff
                    timonwong.shellcheck

                    # git
                    mhutchie.git-graph

                    # copilot
                    github.copilot
                    github.copilot-chat
                  ]
                  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
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
                      name = "specstory-vscode";
                      publisher = "specstory";
                      version = "0.19.1";
                      sha256 = "sha256-ivCZL7lJ1G3sb2VQyoxO4KdG7dHJldagpYlmYpOdmVo=";
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
                    {
                      name = "opencode";
                      publisher = "sst-dev";
                      version = "0.0.13";
                      sha256 = "1m301j2qbym3j2qnck76jyxakca3h1qiybc2r7wy7z11m98mg9z9";
                    }
                  ];
              })
            ];

        # Symlink entire VS Code Copilot prompts and instructions directories
        home.file = mkIf cfg.copilotPrompts.enable (
          let
            inherit (config.lib.file) mkOutOfStoreSymlink;
          in
          {
            # Symlink entire directories to access all chatmodes and prompts
            ".config/Code/User/instructions".source =
              mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/instructions";
            ".config/Code/User/prompts".source =
              mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts";
          }
        );
      };
  };
}
