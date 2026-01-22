{ self, inputs, ... }:
let
  fleetConfig = import ../fleet-config.nix;
  hosts = fleetConfig.hosts;
in
{
  flake.deploy = {
    sshUser = "jarvis"; # Global SSH user for all nodes

    nodes = {
      cortex = {
        hostname = hosts.cortex.ip;
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.cortex;
          user = "root"; # Activate as root (via sudo)
        };
      };
      nexus = {
        hostname = hosts.nexus.ip;
        sshUser = hosts.nexus.ssh.user; # Override global SSH user for Nexus
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nexus;
          user = "root"; # Activate as root (via sudo)
        };
      };
      axon = {
        hostname = hosts.axon.ip;
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.axon;
          user = "root"; # Activate as root (via sudo)
        };
      };
      # Add other systems here as needed
    };
  };

  # Add deploy-rs checks
  flake.checks = builtins.mapAttrs (
    system: deployLib: deployLib.deployChecks self.deploy
  ) inputs.deploy-rs.lib;
}
