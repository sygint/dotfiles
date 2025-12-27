{ config, pkgs, ... }: {
  # VM debug credentials
  users.users.syg.initialPassword = "test";
  users.users.root.initialPassword = "test";

  # Autologin (using correct option names - not sddm-specific)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "syg";

  # SSH for debugging (optional)
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;

  # Port forwarding for SSH
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 2222; guest.port = 22; }
  ];
}
so we can create racial factions devoid of scientific logic