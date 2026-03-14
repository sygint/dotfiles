{
  config,
  lib,
  pkgs,
  userVars,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    mkIf
    types
    optionals
    ;
  cfg = config.modules.features.security;
in
{
  options.modules.features.security = {
    enable = mkEnableOption "Basic security (sudo, polkit, gnome-keyring)";

    hardening = {
      enable = mkEnableOption "Security hardening (fail2ban, auditd) for servers";
    };
  };

  config = mkIf cfg.enable {
    security = {
      sudo = {
        enable = true;
        wheelNeedsPassword = true;
      };

      rtkit.enable = true;
      polkit.enable = true;
    };

    # Enable gnome-keyring for secure storage (works in all desktop environments)
    services.gnome.gnome-keyring.enable = true;

    # PAM configuration for gnome-keyring automatic unlock on TTY login
    security.pam.services = {
      login.enableGnomeKeyring = true;
    };

    # Graphical askpass for sudo/SSH in environments without a TTY (e.g. VSCode terminal).
    # openssh-askpass is the official OpenSSH GTK3 askpass — minimal, Wayland-native,
    # tiny attack surface (~150 lines of C). It pops a password dialog and returns the
    # passphrase on stdout, nothing else.
    environment.variables = {
      SUDO_ASKPASS = "${pkgs.openssh-askpass}/bin/ssh-askpass";
      SSH_ASKPASS = lib.mkForce "${pkgs.openssh-askpass}/bin/ssh-askpass";
    };

    # Install secret management tools
    environment.systemPackages =
      with pkgs;
      [
        libsecret # For secret-tool command-line access
        openssh-askpass # GTK3 graphical password prompt for sudo/SSH
      ]
      ++ (optionals cfg.hardening.enable [
        # Security hardening tools
        fail2ban
        audit
      ]);

    # Security hardening for servers (fail2ban, auditd)
    services.fail2ban = mkIf cfg.hardening.enable {
      enable = true;
      maxretry = 3;
      ignoreIP = [
        "127.0.0.1/8"
        "192.168.1.0/24" # Local network
      ];
      jails.sshd.settings = {
        enabled = true;
        filter = "sshd";
        action = "iptables[name=SSH, port=ssh, protocol=tcp]";
      };
    };

    # auditd - System call auditing
    security.auditd.enable = mkIf cfg.hardening.enable true;
    security.audit = mkIf cfg.hardening.enable {
      enable = true;
      rules = [
        # Log all authentication attempts
        "-w /var/log/auth.log -p wa -k auth"
        "-w /var/log/faillog -p wa -k logins"

        # Monitor SSH activity
        "-w /etc/ssh/sshd_config -p wa -k sshd_config"

        # Monitor sudo usage
        "-w /etc/sudoers -p wa -k sudoers"
        "-w /etc/sudoers.d/ -p wa -k sudoers"

        # Monitor user/group modifications
        "-w /etc/passwd -p wa -k identity"
        "-w /etc/group -p wa -k identity"
        "-w /etc/shadow -p wa -k identity"
      ];
    };
  };
}
