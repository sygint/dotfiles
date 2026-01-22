# Security Documentation

Comprehensive security configuration and hardening guides for all systems.

## Quick Links

- **[SECURITY.md](SECURITY.md)** - General security configuration and best practices
- **[CORTEX-SECURITY.md](CORTEX-SECURITY.md)** - Cortex-specific security hardening
- **[SECURITY-ROADMAP.md](SECURITY-ROADMAP.md)** - Security implementation roadmap
- **[SECURITY-SCANNING.md](SECURITY-SCANNING.md)** - Secret scanning and pre-commit hooks
- **[SECURITY-IMPROVEMENTS.md](SECURITY-IMPROVEMENTS.md)** - Planned security enhancements

## Overview

This directory contains all security-related documentation for the NixOS fleet, including:

### System Hardening
- SSH configuration and key-based authentication
- Firewall rules and network security
- User permissions and sudo configuration
- Kernel hardening parameters
- Fail2ban intrusion prevention

### Secrets Management
- sops-nix integration with age encryption
- Age key management and rotation
- Secret scanning and prevention
- Pre-commit hooks for secret detection

### Monitoring & Auditing
- Audit logging with auditd
- Security event monitoring
- Log aggregation with Loki
- Alert configuration

## System-Specific Security

### Cortex (AI Server)
See [CORTEX-SECURITY.md](CORTEX-SECURITY.md) for:
- Remote access hardening
- Service user security
- AI workload isolation
- Automated deployment security

### Nexus (Homelab)
- Service isolation
- Container security
- Media server access control
- Network segmentation

### Orion (Workstation)
- Desktop security
- Development environment hardening
- Browser security configuration
- Disk encryption

### Axon (HTPC)
- Kiosk mode security
- User privilege separation
- Media access controls
- Physical security considerations

## Implementation Status

Refer to [SECURITY-ROADMAP.md](SECURITY-ROADMAP.md) for current implementation status and planned improvements.

## Contributing

When making security-related changes:

1. **Test thoroughly** - Security changes can break systems
2. **Document changes** - Update relevant docs
3. **Follow principles** - Maintain least-privilege model
4. **Scan for secrets** - Pre-commit hooks will catch them
5. **Review carefully** - Security is critical

## Related Documentation

- [../../SECRETS.md](../../SECRETS.md) - Secrets management guide
- [../../FLEET-MANAGEMENT.md](../../FLEET-MANAGEMENT.md) - Secure deployment practices
- [../BOOTSTRAP.md](../BOOTSTRAP.md) - Secure system bootstrap process
