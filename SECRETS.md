# Secrets Management

Secrets management with sops-nix and age encryption.

---

## Quick Start

### Common Commands

```bash
# Edit secrets (opens in sops editor)
fleet secrets edit
# or: sops ../nixos-secrets/secrets.yaml

# Rekey secrets after adding new host keys
fleet secrets rekey
# or: cd ../nixos-secrets && sops updatekeys -y secrets.yaml

# Deploy (secrets auto-sync via fleet)
fleet push cortex
sudo nixos-rebuild switch --flake .#orion

# Manual secrets sync
fleet secrets sync
```

### Quick Reference

- **Secrets location**: `../nixos-secrets/secrets.yaml`
- **Encryption**: age with SSH host keys
- **Auto-sync**: `fleet push` syncs secrets automatically (`--no-sync` to skip)

---

## Architecture

### Directory Structure

```
dotfiles/ (public repo)
└── nixos-secrets/ (private git submodule)
    ├── .sops.yaml           # SOPS configuration (age keys)
    ├── secrets.yaml         # Encrypted secrets file
    ├── secrets_template.yaml # Template for new secrets
    ├── default.nix          # Nix module (imported by flake)
    └── keys/
        ├── age-key.txt      # Personal age key (backup)
        ├── liveiso          # Live ISO SSH keys
        ├── liveiso.pub
        └── hosts/           # Per-host age keys
            ├── orion.txt
            └── cortex.txt
```

### Key Features

- **Optional**: System builds without secrets (graceful degradation)
- **Per-host**: Each system has its own decryption key derived from SSH host key
- **Version controlled**: Private git submodule tracks changes
- **Auto-sync**: Secrets automatically sync before every deployment

### Flake Integration

```nix
# flake.nix
inputs = {
  nixos-secrets.url = "git+file:../nixos-secrets";
};

# System configuration imports secrets conditionally
imports = [
  # ...
] ++ lib.optionals hasSecrets [
  (import (inputs.nixos-secrets + "/default.nix") { inherit config lib pkgs inputs hasSecrets; })
];
```

---

## How It Works

Deploy flow when running `fleet push <host>`:

1. Fleet pulls latest secrets repo and updates the flake input
2. Nix build includes current secrets in the closure
3. Closure (with encrypted secrets) is copied to the target host
4. sops-nix decrypts secrets on the target using its SSH host key
5. System activates with secrets available at their configured paths

---

## Common Operations

### Add New Secret

```bash
# Edit secrets file (add your secret, save & exit)
fleet secrets edit

# Commit to secrets repo
cd ../nixos-secrets
git add secrets.yaml
git commit -m "Add new API key"

# Add secret definition in nixos-secrets/default.nix
# sops.secrets."api_keys/openai" = {};

# Reference in your NixOS config
# environment.variables.OPENAI_API_KEY = config.sops.secrets."api_keys/openai".path;

# Deploy
fleet push cortex
```

### Add New Host

```bash
# Generate age key from new host's SSH key
ssh newhost "sudo cat /etc/ssh/ssh_host_ed25519_key.pub" | ssh-to-age

# Save the key
cd ../nixos-secrets
echo "age1..." > keys/hosts/newhost.txt

# Add &newhost anchor to .sops.yaml and include in creation_rules

# Rekey all secrets for the new host
fleet secrets rekey

# Commit and deploy
git add .
git commit -m "Add newhost age key"
fleet push newhost
```

### Update Secret

```bash
fleet secrets edit          # Modify value, save & exit
cd ../nixos-secrets
git add secrets.yaml
git commit -m "Update API key"
fleet push cortex
```

### Rekey After Key Changes

```bash
fleet secrets rekey

# Verify decryption works
cd ../nixos-secrets
sops --decrypt --extract '["jarvis"]["password_hash"]' secrets.yaml
```

---

## Troubleshooting

### Secret Not Decrypting

Activation fails with sops decryption error.

```bash
# Verify the host's age key matches what's in .sops.yaml
ssh target-host "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
# Compare output with nixos-secrets/keys/hosts/<hostname>.txt

# If mismatched, update the key file and rekey
fleet secrets rekey
```

### Secrets Out of Sync

Deployed system has old secrets.

```bash
# Redeploy (auto-syncs secrets)
fleet push cortex

# Or sync manually without deploying
fleet secrets sync
```

### Cannot Edit Secrets

`sops` command fails or doesn't decrypt.

```bash
# Ensure your personal age key is available
cat ~/.config/sops/age/keys.txt
# or set explicitly:
export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt

# Then edit
sops ../nixos-secrets/secrets.yaml
```

---

## Resources

- [sops-nix](https://github.com/Mic92/sops-nix) - NixOS integration for SOPS
- [age](https://github.com/FiloSottile/age) - Encryption tool
- [SOPS](https://github.com/mozilla/sops) - Secrets OPerationS
