
# Homelab Management Strategy

## Proxmox Virtualization Layer
- **Proxmox VE** (HP EliteDesk G4): Hypervisor for all core homelab VMs
	- **NixOS Services VM**: Runs AdGuard Home, Grafana, Prometheus, Loki, etc.
	- **Other VMs**: (future expansion)


## Architecture Overview
- **NixOS Services (as Proxmox VM)**: Centralized flake-based deployment, monitoring stack
- **Other NixOS Systems** (3+ systems): Centralized flake-based deployment

## System Inventory
```
├── proxmox (HP EliteDesk G4)         -> Hypervisor
│   ├── opnsense-vm                   -> Scripts (firewall/gateway)
│   └── nixos-services-vm             -> Flake + Deploy (monitoring, DNS, etc.)
├── nas (NixOS)                       -> Flake + Deploy
├── ai-gaming-server (NixOS)          -> Flake + Deploy  
├── homelab-server (NixOS)            -> Flake + Deploy
└── streaming-clients (NixOS)         -> Flake + Deploy
```

## Deployment & Management Strategy

### Proxmox Host
- Managed via Proxmox web UI and CLI

### NixOS VMs & Systems
- Use flakes and deploy-rs for all NixOS systems (including `nixos-services-vm`)
```bash
# Deploy all systems
deploy .

# Deploy specific system
deploy .#nas
deploy .#ai-server
deploy .#nixos-services-vm
```

## Benefits
1. **Proxmox**: Centralized, professional VM management and snapshots
2. **NixOS**: Proper orchestration for complex multi-system deployments
3. **Best of both worlds**: Right tool for each job (flakes for NixOS)
4. **Gradual adoption**: Can migrate to deploy-rs incrementally
5. **Comprehensive monitoring**: All traffic visible, metrics/logs in NixOS services

## Implementation
1. Set up Proxmox and create NixOS VMs (see bifrost-implementation-guide.md)
2. Extend your flake.nix to include all NixOS systems (including nixos-services-vm)
3. Add deploy-rs or colmena for NixOS deployments
4. Use secrets management (sops-nix) for shared credentials