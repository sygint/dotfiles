# NixOS configuration for Nexus (Homelab)
{ config, pkgs, lib, hasSecrets, inputs, ... }:
{
  imports = [
    # Disk and hardware config (add as needed)
    # ./disk-config.nix
    ../../modules/system/base
    ../../modules/system.nix
    # Add more modules for homelab services below
    # ../../modules/system/homelab-services
  ] ++ lib.optionals hasSecrets [
    (import (inputs.nixos-secrets + "/default.nix") { inherit config lib pkgs inputs hasSecrets; })
  ];

  networking.hostName = "nexus";
  time.timeZone = "UTC";

  # Example: Enable core services (customize as needed)
  services.openssh.enable = true;
  services.fail2ban.enable = true;
  services.prometheus.enable = true;
  services.grafana.enable = true;
  services.home-assistant.enable = true;
  services.jellyfin.enable = true;
  services.nextcloud.enable = true;
  services.borgbackup.jobs = {};

  # Example: Enable virtualization
  virtualisation.libvirtd.enable = true;
  users.users.nexus = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" ];
  };

  # Example: Enable firewall
  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 80 443 ];

  # Add more configuration as needed

  system.stateVersion = "24.11";
}
