{ self, inputs, ... }:
{
  flake.deploy = {
    sshUser = "jarvis"; # Global SSH user for all nodes

    nodes = {
      cortex = {
        hostname = "192.168.1.7"; # TODO: Switch to cortex.home when DNS is fixed
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.cortex;
          user = "root"; # Activate as root (via sudo)
        };
      };
      nexus = {
        hostname = "192.168.1.22"; # Nexus homelab services server
        sshUser = "admin"; # Override global SSH user for Nexus
        profiles.system = {
          path = inputs.deploy-rs.lib.x86_64-linux.activate.nixos self.nixosConfigurations.nexus;
          user = "root"; # Activate as root (via sudo)
        };
      };
      axon = {
        hostname = "192.168.1.11"; # TODO: Update with actual Axon IP
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
