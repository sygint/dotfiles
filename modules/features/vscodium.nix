{
  config,
  lib,
  pkgs,
  userVars,
  inputs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkIf
    mkOption
    types
    ;
  cfg = config.modules.features.vscodium;
in
{
  options.modules.features.vscodium = {
    enable = mkEnableOption "VSCodium code editor (VS Code without MS branding/telemetry)";

    variant = mkOption {
      type = types.enum [
        "standard"
        "fhs"
      ];
      default = "fhs";
      description = ''
        VSCodium variant to use:
        - standard: Declarative extension management
        - fhs: FHS environment for imperative extension management
      '';
    };
  };

  config = mkIf cfg.enable {
    home-manager.users.${userVars.username} =
      { config, ... }:
      {
        home.packages =
          if cfg.variant == "fhs" then
            [ pkgs.vscodium-fhs ]
          else
            [
              (pkgs.vscode-with-extensions.override {
                vscode = pkgs.vscodium;
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
                  ]
                  ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
                    {
                      name = "gitless";
                      publisher = "maattdd";
                      version = "11.7.2";
                      sha256 = "sha256-rYeZNBz6HeZ059ksChGsXbuOao9H5m5lHGXJ4ELs6xc=";
                    }
                  ];
              })
            ];

        # Symlink VSCodium settings from dotfiles
        home.file =
          let
            inherit (config.lib.file) mkOutOfStoreSymlink;
          in
          {
            ".config/VSCodium/User/settings.json".source =
              mkOutOfStoreSymlink "${inputs.dotfiles.outPath}/.config/VSCodium/User/settings.json";
          };
      };
  };
}
