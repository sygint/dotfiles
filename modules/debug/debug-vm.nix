{ config, pkgs, ... }: {
  # VM debug credentials
  users.users.syg.initialPassword = "test";
  users.users.root.initialPassword = "test";

  # Autologin (using correct option names - not sddm-specific)
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "syg";

  # SSH for debugging
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  services.openssh.settings.PasswordAuthentication = true;

  # Port forwarding for SSH
  virtualisation.forwardPorts = [
    { from = "host"; host.port = 2222; guest.port = 22; }
  ];

  # Enable serial console for text-mode login (bypasses graphics)
  virtualisation.qemu.options = [ "-serial" "mon:stdio" ];
  
  # Auto-login on tty1 as root for debugging
  services.getty.autologinUser = "root";
}
