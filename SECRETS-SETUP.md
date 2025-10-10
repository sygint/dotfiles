# Secrets Management Setup Guide

This NixOS configuration now supports optional secrets management using sops-nix with age encryption via git submodules.

## Architecture

- **Public Repository**: This main dotfiles repo contains all your public NixOS configurations
- **Private Repository**: A separate private repo containing encrypted secrets (added as git submodule)
- **Optional Import**: System builds successfully whether secrets are present or not

## Quick Setup

### 1. Create Private Secrets Repository

```bash
# Create a new private repository on GitHub/GitLab (e.g., "nixos-secrets")
# Clone the template structure
git clone <your-private-repo> /tmp/nixos-secrets
cd /tmp/nixos-secrets

# Copy the example structure
cp -r /home/syg/.config/nixos/secrets-example/* .
```

### 2. Add as Git Submodule

```bash
cd /home/syg/.config/nixos
git submodule add git@github.com:yourusername/nixos-secrets.git secrets
```

### 3. Generate Age Keys

```bash
# Generate your personal age key
age-keygen -o secrets/keys/age-key.txt

# Generate host-specific keys
age-keygen -o secrets/keys/hosts/orion.txt
age-keygen -o secrets/keys/hosts/aida.txt
```

### 4. Configure SOPS

Edit `secrets/.sops.yaml` with your actual age public keys:

```yaml
keys:
  - &syg age1your_personal_public_key_here
  - &orion age1orion_host_public_key_here
  - &aida age1aida_host_public_key_here

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *syg
          - *orion
          - *aida
```

### 5. Create and Encrypt Secrets

```bash
cd secrets
# Create your secrets file
sops secrets.yaml
```

Example secrets structure:
```yaml
wifi:
  password: "your-wifi-password"
user:
  password_hash: "$6$your_password_hash"
ssh:
  private_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    your_private_key_here
    -----END OPENSSH PRIVATE KEY-----
```

## Usage in NixOS Configurations

Once set up, secrets are available at `config.sops.secrets.*`:

```nix
# In any system configuration
{ config, ... }:
{
  # Secrets are automatically available
  networking.wireless.networks."YourWiFi".psk = config.sops.secrets.wifi-password.path;
  
  users.users.syg.hashedPassword = config.sops.secrets.user-password-hash.path;
}
```

## Commands

```bash
# Test builds work without secrets
nix build .#nixosConfigurations.orion.config.system.build.toplevel --dry-run

# Update submodule
git submodule update --remote secrets

# Edit encrypted secrets
cd secrets && sops secrets.yaml
```

## Security Notes

- Keep the main repo public for easy sharing
- Private secrets repo should have restricted access
- Age keys should be backed up securely
- Host keys should be generated on their respective systems for production
- Use different age keys for different environments (dev/staging/prod)

## Production Deployment

For production use with nixos-anywhere:
1. Generate age keys on the target systems
2. Use environment-specific secrets repositories
3. Implement proper key rotation policies
4. Set up audit logging for secrets access
