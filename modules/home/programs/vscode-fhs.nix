{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.modules.programs.vscode-fhs;
in
{
  options.modules.programs.vscode-fhs = {
    enable = mkEnableOption "VS Code (FHS) for imperative extension management";
    copilotPrompts.enable = mkEnableOption "VS Code Copilot Chat prompts and instructions";
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.vscode-fhs ];

    # Symlink entire VS Code Copilot prompts and instructions directories
    home.file = mkIf cfg.copilotPrompts.enable {
      # Symlink entire directories to access all chatmodes and prompts
      ".config/Code/User/instructions".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/instructions";
      ".config/Code/User/prompts".source = 
        config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/nixos/dotfiles/.config/Code/User/prompts";
    };
  };
}
