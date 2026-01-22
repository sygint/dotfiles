# TODO: Enable HTTPS for Internal Services

**Priority**: Medium  
**Target**: Nexus services  
**Estimated Effort**: 2-4 hours

## Problem

Internal services are using unencrypted HTTP, exposing credentials and session data to potential man-in-the-middle attacks on the local network:

- Grafana: `http://nexus.home:3000/`
- Prometheus: `http://127.0.0.1:9090`
- Jellyfin: `http://nexus.home:8096`
- Kanboard API: `http://localhost/jsonrpc.php`

## Impact

- Credentials transmitted in cleartext
- Session cookies can be intercepted
- Vulnerable to ARP spoofing on local network

## Proposed Solution

### Option 1: Reverse Proxy with SSL Termination (Recommended)

```nix
# systems/nexus/default.nix
services.nginx = {
  enable = true;
  recommendedProxySettings = true;
  recommendedTlsSettings = true;
  
  # Generate self-signed cert for homelab
  virtualHosts."nexus.home" = {
    enableACME = false;
    forceSSL = true;
    sslCertificate = "/var/lib/acme/nexus.home/cert.pem";
    sslCertificateKey = "/var/lib/acme/nexus.home/key.pem";
    
    locations."/grafana/" = {
      proxyPass = "http://127.0.0.1:3000";
      extraConfig = ''
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
      '';
    };
    
    locations."/prometheus/" = {
      proxyPass = "http://127.0.0.1:9090";
    };
    
    locations."/jellyfin/" = {
      proxyPass = "http://127.0.0.1:8096";
    };
  };
};

# Update service URLs
services.grafana.settings.server.root_url = "https://nexus.home:443/grafana/";
```

### Option 2: Individual Service HTTPS

Enable HTTPS directly in each service configuration.

### Option 3: Document as Acceptable Risk

If services are truly internal-only and network is trusted, document the decision to use HTTP.

## Implementation Tasks

- [ ] Generate self-signed certificates for nexus.home
- [ ] Configure nginx as reverse proxy with SSL termination
- [ ] Update Grafana root_url to use HTTPS
- [ ] Update Prometheus external_url to use HTTPS
- [ ] Update Jellyfin base URL to use HTTPS
- [ ] Update all documentation with HTTPS URLs
- [ ] Test all services after migration
- [ ] Update firewall rules (allow port 443)

## References

- Security Audit: `docs/REPOSITORY-SECURITY-AUDIT.md` (when created)
- Nexus Config: `systems/nexus/default.nix`
- Fleet Management: `FLEET-MANAGEMENT.md`
