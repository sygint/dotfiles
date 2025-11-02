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
  options.modules.programs.vscode = {
    enable = mkEnableOption "Visual Studio Code code editor";
    copilotPrompts.enable = mkEnableOption "VS Code Copilot Chat prompts and instructions";
  };

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
          # {
          #   name = "pretty-ts-error";
          #   publisher = "yoavbls";
          #   version = "0.6.1";
          #   sha256 = "";
          # }
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

    # Symlink curated VS Code Copilot prompts and instructions
    home.file = mkIf cfg.copilotPrompts.enable {
      # Instructions (language and framework-specific guidelines)
      ".config/Code/User/instructions/conventional-commit.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/instructions/conventional-commit.prompt.md";
      ".config/Code/User/instructions/markdown.instructions.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/instructions/markdown.instructions.md";
      ".config/Code/User/instructions/reactjs.instructions.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/instructions/reactjs.instructions.md";
      ".config/Code/User/instructions/nextjs.instructions.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/instructions/nextjs.instructions.md";
      ".config/Code/User/instructions/nodejs-javascript-vitest.instructions.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/instructions/nodejs-javascript-vitest.instructions.md";

      # Prompts (specific task-oriented prompts)
      ".config/Code/User/prompts/documentation-writer.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/documentation-writer.prompt.md";
      ".config/Code/User/prompts/review-and-refactor.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/review-and-refactor.prompt.md";
      ".config/Code/User/prompts/create-readme.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/create-readme.prompt.md";
      ".config/Code/User/prompts/git-flow-branch-creator.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/git-flow-branch-creator.prompt.md";
      ".config/Code/User/prompts/architecture-blueprint-generator.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/architecture-blueprint-generator.prompt.md";
      ".config/Code/User/prompts/breakdown-plan.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/breakdown-plan.prompt.md";
      ".config/Code/User/prompts/create-implementation-plan.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/create-implementation-plan.prompt.md";
      ".config/Code/User/prompts/javascript-typescript-jest.prompt.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/javascript-typescript-jest.prompt.md";

      # Chat Modes (specialized AI assistant behaviors)
      ".config/Code/User/prompts/critical-thinking.chatmode.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/critical-thinking.chatmode.md";
      ".config/Code/User/prompts/mentor.chatmode.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/mentor.chatmode.md";
      ".config/Code/User/prompts/debug.chatmode.md".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts/debug.chatmode.md";
    };
  };
}
