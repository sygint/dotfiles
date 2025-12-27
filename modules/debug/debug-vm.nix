{ config, pkgs, ... }: {
  users.users.syg.initialPassword = "test";
  users.users.root.initialPassword = "test";
  services.displayManager.sddm.autoLogin.enable = true;
  services.displayManager.sddm.autoLogin.user = "syg";
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "yes";
  services.openssh.passwordAuthentication = true;
  virtualisation.qemu.options = [
    "-device" "virtio-net,netdev=net0"
    "-netdev" "user,id=net0,hostfwd=tcp::2222-:22"
  ];
}
