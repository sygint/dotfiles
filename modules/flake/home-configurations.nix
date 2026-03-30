{ self, inputs, ... }:
let
  # Import shared constants
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) system hostVars;

  inherit (inputs.nixpkgs.legacyPackages.${system}) pkgs;

  # Default to orion for standalone home-manager configurations
  # (these are used when running `home-manager switch` outside of NixOS)
  orionVars = hostVars.orion;
  userVars = orionVars.user;
  systemVars = orionVars.system;

  mkHomeConfiguration =
    _userVars:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit self inputs;
        userVars = _userVars;
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
