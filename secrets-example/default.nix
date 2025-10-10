# Default secrets module that gets imported by the main flake
{ config, lib, pkgs, inputs, ... }:

{
  # Import sops-nix from flake input
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  # Configure sops
  sops = {
    defaultSopsFile = ./secrets.yaml;
    
    # Age configuration
    age = {
      # Use host SSH key for decryption
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      # Or use a dedicated age key file
      # keyFile = "/var/lib/sops-nix/key.txt";
    };

    # Define secrets
    secrets = {
      # System secrets
      "genesis-ssh-key" = {
        path = "/var/lib/secrets/genesis-ssh-key";
        owner = "root";
        group = "root";
        mode = "0600";
      };
      
      # User passwords
      "user-password-syg" = {
        neededForUsers = true;
      };
      
      "user-password-jarvis" = {
        neededForUsers = true;
      };
      
      # Service-specific secrets
      "nextcloud-admin-pass" = {
        owner = "nextcloud";
        group = "nextcloud";
      };
      
      # Database passwords
      "postgres-password" = {
        owner = "postgres";
        group = "postgres";
      };
    };
  };

  # Use secrets in user configuration
  users.users.syg = lib.mkIf (config.sops.secrets."user-password-syg" or null != null) {
    hashedPasswordFile = config.sops.secrets."user-password-syg".path;
  };
  
  users.users.jarvis = lib.mkIf (config.sops.secrets."user-password-jarvis" or null != null) {
    hashedPasswordFile = config.sops.secrets."user-password-jarvis".path;
  };
}
