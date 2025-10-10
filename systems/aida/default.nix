# NixOS configuration for AIDA (Artificial Intelligence Data Analyser)
{ config, pkgs, lib, hasSecrets, ... }:
{
  imports = [
    ./disk-config.nix
  ];

  # Essential boot configuration
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking.hostName = "aida";

  # Simplified Marvel-themed user setup
  users.users = {
    # Main administrative user - Jarvis (Tony's trusted assistant)
    jarvis = {
      isNormalUser = true;
      description = "Jarvis - AI Server Administrator";
      extraGroups = [ "wheel" "networkmanager" "systemd-journal" ];
      # Use secrets for password if available, otherwise leave passwordless
      hashedPasswordFile = if hasSecrets then config.sops.secrets."jarvis/password_hash".path else null;
      openssh.authorizedKeys.keys = [
        # syg's primary key from orion
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMSdxXvx7Df+/2cPMe7C2TUSqRkYee5slatv7t3MG593 syg@nixos"
      ];
    };

    # AI service user - FRIDAY (Focused Research Intelligence Analysis System)
    friday = {
      isSystemUser = true;
      description = "FRIDAY - AI Services User";
      group = "friday";
      extraGroups = [ "systemd-journal" ];
      home = "/var/lib/friday";
      createHome = true;
    };
  };

  # Create corresponding groups
  users.groups = {
    friday = {};
  };

  # Set a timezone
  time.timeZone = "UTC";

  # Enable OpenSSH for LOCAL access only with security hardening  
  services.openssh = {
    enable = true;
    # Listen on all interfaces but firewall will restrict access
    listenAddresses = [
      { addr = "0.0.0.0"; port = 22; }  # Listen on all interfaces
    ];
    settings = {
      # Completely disable root login (best practice)
      PermitRootLogin = "no";
      # Disable password authentication entirely (SSH keys only)
      PasswordAuthentication = false;
      # Additional security settings
      PermitEmptyPasswords = false;
      ChallengeResponseAuthentication = false;
      # Enhanced SSH hardening
      MaxAuthTries = 3;
      ClientAliveInterval = 300;  # 5 minutes
      ClientAliveCountMax = 2;
      Protocol = "2";
      X11Forwarding = false;
      AllowTcpForwarding = false;  # Disable port forwarding
      # Limit users who can SSH (whitelist approach)
      AllowUsers = [ "jarvis" ];
      # Additional hardening
      MaxSessions = 2;
      LoginGraceTime = 30;
      # Network restrictions
      MaxStartups = "3:50:10";  # Limit connection attempts
    };
  };

  # Security hardening and monitoring
  security = {
    # Require password for sudo (production security)
    sudo.wheelNeedsPassword = true;
    
    # Configure sudo rules for service users
    sudo.extraRules = [
      # jarvis user will use default wheel group sudo (password required)
      # No special rules needed - wheel group membership provides sudo access
      {
        users = [ "friday" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl restart friday-*";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/journalctl";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
    
    # Disable root login entirely for better security
    # Root access only through sudo from jarvis user
    
    # Enable audit logging for security monitoring
    auditd.enable = true;
    audit = {
      enable = true;
      rules = [
        # Monitor authentication events
        "-w /var/log/auth.log -p wa -k auth"
        # Monitor sudo usage and privilege escalation
        "-w /etc/sudoers -p wa -k sudoers"
        "-w /etc/sudoers.d -p wa -k sudoers"
        # Monitor SSH configuration changes
        "-w /etc/ssh/sshd_config -p wa -k ssh"
        # Monitor user/group changes
        "-w /etc/passwd -p wa -k passwd"
        "-w /etc/group -p wa -k group"
        "-w /etc/shadow -p wa -k passwd"
        # Monitor login/logout events
        "-w /var/log/wtmp -p wa -k logins"
        "-w /var/log/btmp -p wa -k logins"
        # Monitor service user directories
        "-w /var/lib/friday -p wa -k friday-access"
        # Monitor systemd service changes
        "-w /etc/systemd/system -p wa -k systemd-changes"
      ];
    };
  };

  # Fail2ban - Automatic IP blocking for brute force protection
  services.fail2ban = {
    enable = true;
    ignoreIP = [
      "127.0.0.0/8"          # Localhost
      "192.168.0.0/16"       # Local network ranges
      "10.0.0.0/8"           # Private network range
      "172.16.0.0/12"        # Private network range
    ];
    # Default SSH jail is automatically enabled - we can customize it further if needed
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Network configuration with strict firewall
  networking = {
    networkmanager.enable = true;
    
    # Enable firewall with strict rules - only allow Orion access
    firewall = {
      enable = true;
      # No ports open by default - SSH access controlled by extraCommands
      allowedTCPPorts = [ ];
      # Disable ping responses for stealth
      allowPing = false;
      # Log suspicious traffic
      logReversePathDrops = true;
      
      # Strict firewall rules - only allow Orion machine access
      extraCommands = ''
        # Allow loopback traffic
        iptables -A INPUT -i lo -j ACCEPT
        
        # Allow established and related connections
        iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        
        # Allow SSH only from local network ranges (adjust to your network)
        # You may want to make this more specific to Orion's exact IP
        iptables -A INPUT -p tcp --dport 22 -s 192.168.0.0/16 -j ACCEPT
        iptables -A INPUT -p tcp --dport 22 -s 10.0.0.0/8 -j ACCEPT
        iptables -A INPUT -p tcp --dport 22 -s 172.16.0.0/12 -j ACCEPT
        
        # Allow minimal ICMP for network diagnostics (from local networks only)
        iptables -A INPUT -p icmp --icmp-type echo-request -s 192.168.0.0/16 -j ACCEPT
        iptables -A INPUT -p icmp --icmp-type echo-request -s 10.0.0.0/8 -j ACCEPT
        iptables -A INPUT -p icmp --icmp-type echo-request -s 172.16.0.0/12 -j ACCEPT
        
        # Log and drop everything else
        iptables -A INPUT -j LOG --log-prefix "AIDA-FIREWALL-DROP: " --log-level 4
        iptables -A INPUT -j DROP
        
        # Also restrict outbound traffic (optional - uncomment if desired)
        # iptables -A OUTPUT -o lo -j ACCEPT
        # iptables -A OUTPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
        # iptables -A OUTPUT -p tcp --dport 80 -j ACCEPT   # HTTP
        # iptables -A OUTPUT -p tcp --dport 443 -j ACCEPT  # HTTPS  
        # iptables -A OUTPUT -p tcp --dport 53 -j ACCEPT   # DNS
        # iptables -A OUTPUT -p udp --dport 53 -j ACCEPT   # DNS
        # iptables -A OUTPUT -j LOG --log-prefix "AIDA-OUTBOUND-DROP: "
        # iptables -A OUTPUT -j DROP
      '';
    };
  };
  
  # Basic system packages
  environment.systemPackages = with pkgs; [
    # Add any additional packages here if needed
  ];

  # System monitoring and logging
  services = {
    # System journal configuration
    journald.extraConfig = ''
      SystemMaxUse=1G
      SystemMaxFiles=10
      MaxRetentionSec=1month
    '';
    
    # Enable chronyd for accurate time (important for logs and security)
    chrony.enable = true;
  };

  # System hardening
  boot.kernel.sysctl = {
    # Network security
    "net.ipv4.ip_forward" = 0;
    "net.ipv4.conf.all.send_redirects" = 0;
    "net.ipv4.conf.default.send_redirects" = 0;
    "net.ipv4.conf.all.accept_redirects" = 0;
    "net.ipv4.conf.default.accept_redirects" = 0;
    "net.ipv4.conf.all.accept_source_route" = 0;
    "net.ipv4.conf.default.accept_source_route" = 0;
    
    # Prevent SYN flood attacks
    "net.ipv4.tcp_syncookies" = 1;
    "net.ipv4.tcp_max_syn_backlog" = 2048;
    "net.ipv4.tcp_synack_retries" = 2;
    "net.ipv4.tcp_syn_retries" = 5;
  };

  # Set state version
  system.stateVersion = "24.11";
}
