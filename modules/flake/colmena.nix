{ inputs, lib, ... }:

let
  fleetConfig = import ../../fleet-config.nix;

  # Import shared constants and system definitions
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) systems hostVars;
in

{
  # Declare colmena as a known flake output to avoid flake-parts warnings
  options.flake.colmena = lib.mkOption {
    type = lib.types.lazyAttrsOf lib.types.raw;
    default = { };
    description = "Colmena deployment configuration";
  };

  config.flake.colmena = {
    meta = {
      # Colmena expects nixpkgs at top level - use flake input path
      nixpkgs = inputs.nixpkgs.outPath;

      specialArgs = {
        inherit inputs;
        fh = inputs.fh;
        fleetConfig = fleetConfig;
        nodeHasSecrets = lib.mapAttrs (name: cfg: cfg.hasSecrets) systems;
        hasSecrets = false;
      };
    };
  }
  // lib.mapAttrs (
    name: hostCfg:
    let
      systemCfg = systems.${name};
      vars = hostVars.${name};
    in
    {
      # Colmena requires a type attribute
      type = "none";

      deployment = {
        targetHost = hostCfg.ip;
        targetUser = hostCfg.ssh.user or "root";
        targetPort = hostCfg.ssh.port or 22;
        buildOnTarget = hostCfg.deploy.remoteBuild or false;
        tags = hostCfg.tags or [ ];
      };

      _module.args = {
        userVars = vars.user;
        hasSecrets = systemCfg.hasSecrets;
      };

      # Use paths for colmena
      imports = [ systemCfg.path ] ++ systemCfg.modules;
    }
  ) fleetConfig.hosts;
}
