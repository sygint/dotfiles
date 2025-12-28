{ config
, lib
, options
, pkgs
, ...
}:
let
  inherit (lib) mkEnableOption mkIf mkOption types;
  cfg = config.modules.system.security;
in
{
  options.modules.system.security = {
    enable = mkEnableOption "Basic security (sudo, polkit, etc.)";
    
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

    # Install secret management tools
    environment.systemPackages = with pkgs; [
      libsecret # For secret-tool command-line access
    ] ++ (lib.optionals cfg.hardening.enable [
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
        "192.168.1.0/24"  # Local network
      ];
      jails.sshd = ''
        enabled = true
        filter = sshd
        action = iptables[name=SSH, port=ssh, protocol=tcp]
      '';
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
