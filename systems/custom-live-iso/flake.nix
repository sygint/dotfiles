{
  description = "Custom NixOS Live ISO with SSH enabled for nixos-anywhere";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations.installer = nixpkgs.lib.nixosSystem {
        system = system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
          ({ pkgs, modulesPath, lib, ... }: {
            # ISO configuration
            isoImage.isoName = lib.mkForce "nixos-homelab-installer.iso";
            
            # Enable SSH by default
            services.openssh = {
              enable = true;
              settings = {
                # SSH key authentication only (secure for nixos-anywhere)
                # Use mkForce to override the installation-device.nix default
                PermitRootLogin = lib.mkForce "prohibit-password";
                PasswordAuthentication = false;
              };
              # Only allow SSH from local network
              listenAddresses = [
                { addr = "0.0.0.0"; port = 22; }
              ];
            };
            
            # Firewall: Only allow SSH from local network
            networking.firewall = {
              enable = true;
              allowedTCPPorts = [ 22 ];
              # Restrict SSH to local network (192.168.x.x, 10.x.x.x, 172.16-31.x.x)
              extraCommands = ''
                iptables -A nixos-fw -p tcp --dport 22 -s 192.168.0.0/16 -j nixos-fw-accept
                iptables -A nixos-fw -p tcp --dport 22 -s 10.0.0.0/8 -j nixos-fw-accept
                iptables -A nixos-fw -p tcp --dport 22 -s 172.16.0.0/12 -j nixos-fw-accept
                iptables -A nixos-fw -p tcp --dport 22 -j nixos-fw-log-refuse
              '';
            };
            
            # Pre-configure SSH authorized keys for root (for nixos-anywhere)
            users.users.root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
            ];
            
            # Console password for physical access / troubleshooting
            users.users.root.password = "nixos";
            
            # Create deploy user for consistent deployment workflow
            # This ensures systems bootstrapped from this ISO already have the deploy user configured
            users.users.deploy = {
              isNormalUser = true;
              description = "Deployment user for remote management";
              extraGroups = [ "wheel" "networkmanager" ];
              openssh.authorizedKeys.keys = [
                "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
              ];
              password = "deploy"; # Console access if needed during installation
            };
            
            # Enable passwordless sudo for wheel group (needed for deploy-rs and remote management)
            security.sudo.wheelNeedsPassword = false;
            
            # Useful packages for installation
            environment.systemPackages = with pkgs; [
              vim
              git
              curl
              htop
              tmux
            ];
            
            # Network configuration
            networking.useDHCP = true;
            networking.wireless.enable = false; # Disable wifi, use ethernet
          })
        ];
      };
    };
}
