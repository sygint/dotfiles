{ self, inputs, ... }:
let
  # Import shared constants
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) system userVars systemVars;

  inherit (inputs.nixpkgs.legacyPackages.${system}) pkgs;

  mkHomeConfiguration =
    _userVars:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit self inputs;
        userVars = _userVars;
        opencode = inputs.opencode.packages.${system};
      };
      modules = [
        inputs.nix-flatpak.homeManagerModules.nix-flatpak
        ../systems/orion/homes/syg.nix
        {
          nixpkgs.config.allowUnfree = true;
        }
      ];
    };
in
{
  flake.homeConfigurations = {
    ${userVars.username} = mkHomeConfiguration userVars;
    "${userVars.username}@${systemVars.hostName}" = mkHomeConfiguration userVars;
  };
}
