# Security Roadmap

## Future Security Enhancements for Homelab 🛡️

**Status:** Conceptual / Not Yet Implemented  
**Purpose:** Document potential security improvements and architectures to consider for future homelab expansion

> **Note:** This document describes *potential* security architectures, not the current implementation. See `systems/cortex/default.nix` and other system configs for actual current security measures.

## User Isolation Strategy Concepts

### Current Setup (As Implemented)
```
Cortex (AI Server):
└── jarvis: 👤 Admin user
    ├── SSH: ✅ Key-only auth
    ├── Sudo: ✅ Full access
    └── Service Users:
        └── friday: 🤖 AI services (isolated)

Orion (Workstation):
└── syg: 👤 Primary user
    ├── Desktop environment
    └── Development tools
```

### Potential Enhanced Architecture (Future Consideration)
```
Concept: Functional Role-Based Access
└── Admin tier:
    ├── admin: 👤 System administration
    └── Service tier:
        ├── ai-svc: 🤖 AI services (Ollama, etc.)
        ├── monitor-svc: 🛡️ Security monitoring (fail2ban, intrusion detection)
        └── metrics-svc: � Analytics services (Prometheus, Grafana)
```

### Potential Security Improvements to Consider

| Feature | Current State | Potential Enhancement | Benefit |
|---------|---------------|----------------------|---------|
| **User Naming** | Descriptive (jarvis, friday) | Role-based (admin, ai-svc) | ✅ Clearer purpose |
| **Service Isolation** | Some isolation (friday user) | Full isolation per service | ✅ Better containment |
| **Network Segmentation** | Ubiquiti firewall rules | VLANs + microsegmentation | ✅ Layer 2 isolation |
| **Audit Granularity** | System-level auditd | Per-user audit trails | ✅ Enhanced forensics |
| **Secret Management** | sops-nix (current) | Vault or similar | ✅ Dynamic secrets |
| **Zero Trust** | Firewall + SSH keys | mTLS + per-service auth | ✅ Defense in depth |

## Network Architecture Considerations

### Current Homelab Setup
```
Internet → Ubiquiti UDM/USW
├── Orion (Workstation) - 192.168.1.100
├── Cortex (AI Server) - 192.168.1.7
├── Nexus (Homelab Services) - 192.168.1.10
└── Synology DS920+ - 192.168.1.50
```

### Potential VLAN Segmentation (Future)
```
Management VLAN (10):
├── Ubiquiti devices
└── Admin workstations

Server VLAN (20):
├── Cortex (AI)
└── Nexus (Services)

IoT/Camera VLAN (30):
├── Security cameras (when added)
└── Smart home devices

Storage VLAN (40):
└── Synology NAS
```

## Potential Operational Improvements

### Service User Isolation Pattern
```nix
# Example pattern for isolated service users
users.users.servicename = {
  isSystemUser = true;
  group = "servicename";
  home = "/var/lib/servicename";
  createHome = true;
};

# Limited sudo rules
security.sudo.extraRules = [{
  users = [ "servicename" ];
  commands = [{
    command = "/run/current-system/sw/bin/systemctl restart servicename-*";
    options = [ "NOPASSWD" ];
  }];
}];
```

### Ubiquiti Integration Ideas

**Firewall Rules (UDM/USG):**
- Geo-blocking for SSH (allow only home country)
- Rate limiting on management ports
- IDS/IPS for anomaly detection

**Network Policies:**
- IoT device isolation (cameras can't reach internet)
- Inter-VLAN rules (storage only accessible from server VLAN)
- Guest network completely isolated

## Security Principles Worth Considering

### Currently Implemented ✅
1. **SSH Key-Only Authentication** - No passwords accepted
2. **Root Login Disabled** - Must sudo from user account
3. **Fail2ban** - Automatic IP blocking for brute force attempts
4. **Audit Logging** - Track security-relevant events
5. **Firewall** - Restrictive rules, LAN-only access
6. **Service Isolation** - Separate user for AI services (friday)

### Potential Future Enhancements ⏳
1. **Network Segmentation** - VLANs for different security zones
2. **mTLS** - Mutual TLS for service-to-service communication
3. **Hardware Security Keys** - YubiKey/Nitrokey for admin access
4. **Intrusion Detection** - Suricata/Snort on Ubiquiti
5. **Automated Backups** - Encrypted, tested backup strategy
6. **Secret Rotation** - Automatic credential rotation
7. **Monitoring Dashboard** - Centralized security monitoring (Grafana/Prometheus)

## Implementation Considerations

### What Works Well for Homelab
- NixOS declarative configuration (reproducible security)
- SSH key authentication (simple, effective)
- Ubiquiti ecosystem (integrated firewall/IDS/IPS)
- Tailscale (secure remote access without port forwarding)

### What Might Be Overkill
- Enterprise IAM systems (Keycloak, etc.)
- Full zero-trust architecture
- Extensive compliance frameworks
- 24/7 SOC monitoring

### Sweet Spot for Homelab Security
1. Strong firewall rules (Ubiquiti)
2. SSH keys + Fail2ban
3. Basic VLANs (trusted/IoT/guest)
4. Automated updates (NixOS)
5. Regular backups (encrypted)
6. Monitoring alerts (critical services only)

---

**Remember:** Security is about risk management. Perfect security doesn't exist, but you can be secure enough for your threat model. For a homelab, focus on the high-impact, low-effort wins! 🎯
