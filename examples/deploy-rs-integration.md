# Deploy-rs Integration for AIDA

This document explains how to integrate deploy-rs for automated NixOS deployments to AIDA.

## Adding deploy-rs to flake.nix

### 1. Add deploy-rs input

```nix
{
  inputs = {
    # ... your existing inputs
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
```

### 2. Add deploy-rs to outputs

```nix
outputs = { self, nixpkgs, ..., deploy-rs, ... } @ inputs:
```

### 3. Configure deployment nodes

Add this to your flake outputs:

```nix
{
  outputs = { ... }: {
    # ... your existing nixosConfigurations

    # Deploy-rs configuration for remote deployments
    deploy.nodes = {
      aida = {
        hostname = "aida.local";  # or IP address like "192.168.1.213"
        profiles.system = {
          user = "root";
          path = deploy-rs.lib.x86_64-linux.activate.nixos 
                 self.nixosConfigurations.aida;
        };
      };
    };

    # Deploy-rs checks (highly recommended)
    checks = builtins.mapAttrs 
      (system: deployLib: deployLib.deployChecks self.deploy) 
      deploy-rs.lib;
  };
}
```

## Usage

### Deploy to AIDA

```bash
# Deploy the aida system configuration
nix run github:serokell/deploy-rs -- .#aida

# Deploy with sudo password
nix run github:serokell/deploy-rs -- .#aida --ssh-opts="-t" --sudo-opts="--preserve-env"

# Deploy with custom options
nix run github:serokell/deploy-rs -- .#aida --skip-checks --magic-rollback false
```

### Common Options

- `--skip-checks` - Skip deployment checks
- `--dry-activate` - Build but don't activate the new configuration  
- `--auto-rollback false` - Disable automatic rollback on failure
- `--magic-rollback false` - Disable magic rollback
- `--confirm` - Ask for confirmation before activation
- `--interactive` - Interactive mode with prompts

## SSH Configuration

Ensure you have SSH access to the target system:

```bash
# Test SSH connection
ssh jarvis@aida.local

# Or with IP
ssh jarvis@192.168.1.213
```

For root deployments, configure sudo or SSH key for root:

```nix
# In your aida configuration
users.users.root.openssh.authorizedKeys.keys = [
  "ssh-ed25519 AAAA... your-key"
];
```

## Troubleshooting

### Rate Limiting

If you encounter GitHub API rate limiting when updating flake.lock:

1. Wait a few minutes and try again
2. Use a GitHub personal access token:
   ```bash
   export GITHUB_TOKEN="your_token_here"
   nix flake lock --update-input deploy-rs
   ```

### Connection Issues

If deployment fails to connect:
- Verify SSH access works manually
- Check firewall rules on target system
- Ensure the hostname resolves correctly

### Build Failures

If builds fail on the remote system:
- Use `--build-on-remote` to build on the target
- Check available disk space on the target
- Review error messages in the deployment output

## Alternative: Manual Deployment with nixos-rebuild

If you prefer not to use deploy-rs, you can deploy manually:

```bash
# Build configuration locally
nixos-rebuild build --flake .#aida

# Copy to remote and activate
nixos-rebuild switch --flake .#aida --target-host jarvis@aida.local --use-remote-sudo
```

Or use the provided scripts:

```bash
# Deploy aida using nixos-anywhere (for initial setup)
./scripts/deploy-aida.sh [target-ip] [target-user]

# For updates after initial setup
ssh jarvis@aida.local "cd /etc/nixos && git pull && sudo nixos-rebuild switch --flake .#aida"
```

## See Also

- [deploy-rs Documentation](https://github.com/serokell/deploy-rs)
- [NixOS Manual - Remote Builds](https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html)
- [AIDA-SECURITY.md](../AIDA-SECURITY.md) - Security implementation details
