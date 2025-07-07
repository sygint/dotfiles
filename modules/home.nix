{ lib, ... }:
{
  imports = [
    # Program modules
    ./home/programs/git.nix
    ./home/programs/brave.nix
    ./home/programs/librewolf.nix
    ./home/programs/vscode.nix
    ./home/programs/btop.nix
    ./home/programs/kitty.nix
    ./home/programs/zsh.nix
    ./home/programs/hyprland.nix
    ./home/programs/hyprpanel.nix
  ];
}