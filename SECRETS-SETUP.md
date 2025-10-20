# Secrets Management Guide

This configuration uses **sops-nix** with **age encryption** for secure secrets management. Secrets are stored in a private git submodule (`nixos-secrets/`) that is **optionally imported** - the system builds successfully whether secrets are present or not.

## Architecture

```
dotfiles/ (public repo)
└── nixos-secrets/ (private git submodule)
    ├── .sops.yaml           # SOPS configuration (age keys)
    ├── secrets.yaml         # Encrypted secrets file
    ├── default.nix          # Nix module (imported by flake)
    └── keys/
        ├── age-key.txt      # Personal age key (backup)
        ├── liveiso/         # Live ISO SSH keys
        └── hosts/           # Per-host age keys
            ├── orion.txt
            └── cortex.txt
```

**Key Features:**
- ✅ Optional: System builds without secrets
- ✅ Encrypted: All secrets encrypted with age keys
- ✅ Per-host: Each system has its own decryption key
- ✅ Version controlled: Private git submodule tracks changes

## Current Usage

Secrets are currently used in this configuration for:

### Cortex (AI Server)
```nix
# systems/cortex/default.nix
users.users.jarvis = {
  hashedPasswordFile = config.sops.secrets."jarvis/password_hash".path;
};
```

**Secret path**: `jarvis/password_hash`  
**Purpose**: Admin user password hash for Cortex

## How It Works

### 1. Encryption Keys

Each system uses its **SSH host key** for decryption:
```nix
# nixos-secrets/default.nix
sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
```

On first boot, the system automatically:
1. Reads encrypted `secrets.yaml`
2. Decrypts using `/etc/ssh/ssh_host_ed25519_key`
3. Makes secrets available at `/run/secrets/*`

### 2. Secret Definition

In `nixos-secrets/default.nix`:
```nix
sops.secrets = {
  "jarvis/password_hash" = {
    neededForUsers = true;  # Available before user creation
  };
};
```

### 3. Secret Usage

In system configs:
```nix
users.users.jarvis = {
  hashedPasswordFile = config.sops.secrets."jarvis/password_hash".path;
  # Expands to: /run/secrets/jarvis/password_hash
};
```

## Adding New Secrets

### Step 1: Edit Encrypted File

```bash
cd nixos-secrets
sops secrets.yaml
```

This opens your editor with decrypted content. Add your secret:
```yaml
# Example structure
jarvis:
  password_hash: "$6$rounds=656000$..."

# Add new secrets
wifi:
  home_password: "your-wifi-password"

api_keys:
  openai: "sk-..."
  github: "ghp_..."
```

Save and close - sops automatically re-encrypts.

### Step 2: Define in default.nix

```nix
# nixos-secrets/default.nix
sops.secrets = {
  "jarvis/password_hash" = {
    neededForUsers = true;
  };
  
  # Add new secret definitions
  "wifi/home_password" = {
    owner = "root";
    mode = "0440";
  };
  
  "api_keys/openai" = {
    owner = "syg";
    mode = "0400";
  };
};
```

### Step 3: Use in Configuration

```nix
# systems/orion/default.nix
networking.wireless.networks."HomeWiFi" = {
  pskRaw = config.sops.secrets."wifi/home_password".path;
};

# Or in home configuration
home.file.".openai_key" = {
  source = config.sops.secrets."api_keys/openai".path;
};
```

### Step 4: Commit and Deploy

```bash
cd nixos-secrets
git add secrets.yaml default.nix
git commit -m "add: WiFi and API key secrets"
git push

cd ..
git add nixos-secrets  # Update submodule reference
git commit -m "chore: update secrets submodule"

# Deploy
./scripts/fleet.sh deploy cortex
```

## Managing Keys

### Get Host SSH Public Key

When adding a new system, get its SSH public key for encryption:

```bash
# On the target system
ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub

# Or remotely
ssh root@newsystem "cat /etc/ssh/ssh_host_ed25519_key.pub" | ssh-to-age
```

This outputs an age public key like: `age1abc...xyz`

### Update .sops.yaml

Add the new key to `.sops.yaml`:

```yaml
keys:
  - &syg age1your_personal_key
  - &cortex age1cortex_host_key
  - &newsystem age1newsystem_host_key  # Add new system

creation_rules:
  - path_regex: secrets\.yaml$
    key_groups:
      - age:
          - *syg
          - *cortex
          - *newsystem  # Add here too
```

### Re-encrypt for New Key

```bash
cd nixos-secrets
sops updatekeys secrets.yaml
```

This re-encrypts the file so the new system can decrypt it.

## Common Patterns

### User Passwords

Generate password hash:
```bash
mkpasswd -m sha-512
```

Add to secrets:
```yaml
username:
  password_hash: "$6$..."
```

Use in config:
```nix
users.users.username = {
  hashedPasswordFile = config.sops.secrets."username/password_hash".path;
};
```

### API Keys / Tokens

```yaml
api_keys:
  github: "ghp_..."
  openai: "sk-..."
  anthropic: "sk-ant-..."
```

```nix
sops.secrets."api_keys/github" = {
  owner = "syg";
  mode = "0400";  # Read-only for owner
};
```

### SSH Keys

```yaml
ssh:
  deploy_key: |
    -----BEGIN OPENSSH PRIVATE KEY-----
    ...
    -----END OPENSSH PRIVATE KEY-----
```

```nix
sops.secrets."ssh/deploy_key" = {
  owner = "syg";
  mode = "0600";
  path = "/home/syg/.ssh/deploy_key";
};
```

## Troubleshooting

### Secret not found

**Error**: `error: attribute 'secrets' missing`

**Solution**: Secrets submodule not initialized:
```bash
git submodule update --init --recursive
```

### Permission denied

**Error**: `error: cannot read '/run/secrets/...'`

**Solution**: Check owner/mode in secret definition:
```nix
sops.secrets."mykey" = {
  owner = "syg";     # User who needs access
  mode = "0400";     # Read-only
};
```

### Decryption failed

**Error**: `error: no age identities found`

**Solution**: Check SSH host key exists:
```bash
ls -la /etc/ssh/ssh_host_ed25519_key*
```

If missing, regenerate:
```bash
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
```

Then update `.sops.yaml` with new public key and re-encrypt.

## Security Best Practices

1. **Separate Repositories**: Keep secrets in private repo, main config in public repo
2. **Key Backup**: Backup age keys securely (encrypted backup drive, password manager)
3. **Key Rotation**: Rotate secrets and keys periodically
4. **Least Privilege**: Set appropriate owner/mode for each secret
5. **Audit**: Review `git log` in secrets repo to track changes
6. **No Plaintext**: Never commit plaintext secrets (use `sops` editor only)

## Commands Reference

```bash
# Edit secrets (decrypts, opens editor, re-encrypts on save)
cd nixos-secrets && sops secrets.yaml

# Update keys after adding new system
sops updatekeys secrets.yaml

# View decrypted content (without editing)
sops -d secrets.yaml

# Check which keys can decrypt
sops -d --extract '["sops"]["age"]' secrets.yaml

# Update submodule to latest
git submodule update --remote nixos-secrets

# Initialize submodule on new machine
git submodule update --init --recursive
```

## Learn More

- [sops-nix Documentation](https://github.com/Mic92/sops-nix)
- [age Encryption Tool](https://github.com/FiloSottile/age)
- [SOPS Documentation](https://github.com/mozilla/sops)

---

*Last Updated: October 20, 2025*
