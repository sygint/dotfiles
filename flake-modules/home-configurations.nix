{ self, inputs, ... }:
let
  system = "x86_64-linux";
  inherit (inputs.nixpkgs.legacyPackages.${system}) pkgs;

  # Import variables for home-manager
  variables = import ../systems/orion/variables.nix;
  inherit (variables.user) username;
  userVars = variables.user;
  systemVars = variables.system;

  mkHomeConfiguration =
    variables:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      extraSpecialArgs = {
        inherit self inputs userVars;
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
    ${username} = mkHomeConfiguration userVars;
    "${username}@${systemVars.hostName}" = mkHomeConfiguration userVars;
  };
}
