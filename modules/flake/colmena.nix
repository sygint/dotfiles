{ self, inputs, ... }:
let
  inherit (inputs.nixpkgs) lib;
  fleetConfig = import ../fleet-config.nix;

  # Import shared constants and system definitions — same source as nixos-configurations.nix
  shared = import ./lib.nix { inherit inputs; };
  inherit (shared) systems hostVars;
in
{
  # Generate Colmena hive configuration
  flake.colmena = {
    meta = {
      # Colmena requires nixpkgs at the top level
      nixpkgs = import inputs.nixpkgs {
        system = "x86_64-linux";
        config.allowUnfree = true;
      };

      # Pass through the same specialArgs as nixosConfigurations
      specialArgs = {
        inherit
          self
          inputs
          ;
        fh = inputs.fh;
        fleetConfig = fleetConfig;
        # For Colmena, we can't pass per-node specialArgs easily, so we pass
        # nodeHasSecrets mapping and each system will look up its own value
        nodeHasSecrets = lib.mapAttrs (name: cfg: cfg.hasSecrets) systems;
        # Also provide a default hasSecrets for compatibility
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
      # Deployment configuration from fleet-config.nix
      deployment = {
        targetHost = hostCfg.ip;
        targetUser = hostCfg.ssh.user or "root";
        targetPort = hostCfg.ssh.port or 22;
        # Use buildOnTarget based on fleet-config's deploy.remoteBuild setting
        buildOnTarget = hostCfg.deploy.remoteBuild or false;
        tags = hostCfg.tags or [ ];
      };

      # Per-node specialArgs so modules can access host-specific settings
      _module.args = {
        userVars = vars.user;
        hasSecrets = systemCfg.hasSecrets;
      };

      # Import the same modules as nixosConfigurations
      imports = [ systemCfg.path ] ++ systemCfg.modules;
    }
  ) fleetConfig.hosts;
}
