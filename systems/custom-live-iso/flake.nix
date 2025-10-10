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
          ({ pkgs, modulesPath, ... }: {
            # ISO configuration
            isoImage.isoName = "nixos-anywhere-installer.iso";
            
            # Enable SSH by default
            services.openssh = {
              enable = true;
              settings = {
                PermitRootLogin = "yes";
                PasswordAuthentication = false;
              };
            };
            
            # Pre-configure SSH authorized keys for root
            users.users.root.openssh.authorizedKeys.keys = [
              "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
            ];
            
            # Useful packages for installation
            environment.systemPackages = with pkgs; [
              vim
              git
              curl
              htop
              tmux
            ];
            
            # Set a known root password as fallback (change this!)
            users.users.root.password = "nixos";
            
            # Network configuration
            networking.useDHCP = true;
            networking.wireless.enable = false; # Disable wifi, use ethernet
          })
        ];
      };
    };
}
