# Secrets Management

**Complete guide to secrets management with sops-nix and age encryption.**

**Current Status:** Phase 1 (Hybrid Approach) - Implemented ✅  
**Last Updated:** October 29, 2025

---

## 📋 Table of Contents

1. [Quick Start](#quick-start)
2. [Architecture](#architecture)
3. [Current Setup](#current-setup)
4. [Implementation Guide](#implementation-guide)
5. [Common Operations](#common-operations)
6. [Strategy & Evolution](#strategy--evolution)
7. [Troubleshooting](#troubleshooting)

---

## Quick Start

### Common Commands

```bash
# Edit secrets (opens in sops editor)
just edit-secrets
# or: sops ../nixos-secrets/secrets.yaml

# Rekey secrets after adding new host keys
just rekey
# or: cd ../nixos-secrets && sops updatekeys -y secrets.yaml

# Deploy (secrets auto-sync via rebuild-pre hook)
just deploy-cortex
just rebuild-orion

# Manual secrets sync (usually automatic)
just update-secrets
```

### Quick Reference

- **Secrets location**: `../nixos-secrets/secrets.yaml`
- **Encryption**: age with SSH host keys
- **Auto-sync**: Yes (via `rebuild-pre` hook in justfile)
- **Phase**: 1 (Local + Auto-Sync) ✅

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
            ├── orion.txt    # Orion's age public key
            └── cortex.txt   # Cortex's age public key
```

### Key Features

- ✅ **Optional**: System builds without secrets (graceful degradation)
- ✅ **Encrypted**: All secrets encrypted with age keys
- ✅ **Per-host**: Each system has its own decryption key
- ✅ **Version controlled**: Private git submodule tracks changes
- ✅ **Auto-sync**: Secrets automatically sync before every deployment

### Flake Integration

```nix
# flake.nix
inputs = {
  nixos-secrets.url = "git+file:../nixos-secrets";
  # ... other inputs
};

# System configuration imports secrets conditionally
imports = [
  # ... other imports
] ++ lib.optionals hasSecrets [
  (import (inputs.nixos-secrets + "/default.nix") { inherit config lib pkgs inputs hasSecrets; })
];
```

---

## Current Setup

### Phase 1: Local + Auto-Sync ✅ IMPLEMENTED

**What's Working:**
- ✅ Local git repo at `../nixos-secrets`
- ✅ sops-nix for encryption
- ✅ Age keys for decryption
- ✅ Automatic sync via `rebuild-pre` hook
- ✅ justfile recipes (`edit-secrets`, `rekey`, `update-secrets`)
- ✅ `.sops.yaml` with creation rules

**Justfile Integration:**

```justfile
# Run BEFORE every rebuild/deploy - syncs secrets automatically
rebuild-pre: update-secrets
  @git add --intent-to-add .

# Sync secrets from separate repo (HYBRID APPROACH)
update-secrets:
  @echo "🔄 Syncing secrets..."
  @(cd ../nixos-secrets && git pull) || true
  @nix flake update nixos-secrets --timeout 5
  @echo "✅ Secrets synced"

# Deploy commands automatically call rebuild-pre
deploy-cortex: rebuild-pre
  ./scripts/safe-deploy.sh cortex 192.168.1.7 jarvis
```

**How It Works:**
1. You run `just deploy-cortex` or `just rebuild-orion`
2. `rebuild-pre` hook runs automatically
3. Secrets repo pulls latest changes
4. `nixos-secrets` flake input updated to new commit
5. Build includes current secrets
6. Deploy sends entire closure (with secrets) to target
7. Target activates with correct secrets

---

## Implementation Guide

### Initial Setup

#### 1. Generate Age Keys

**On each host, derive age key from SSH host key:**

```bash
# Find SSH host key
sudo cat /etc/ssh/ssh_host_ed25519_key.pub

# Convert to age public key
nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
```

**Save the output** to `nixos-secrets/keys/hosts/<hostname>.txt`

#### 2. Configure .sops.yaml

```yaml
# nixos-secrets/.sops.yaml
keys:
  - &cortex age1ccggc62tl27hg7unjtg4v7kpryalaqslafhwgwgmazgagv9ru9jslcvm8m
  - &orion age1u6xgw7xce5vvkxv4vchck845qv6k43hh89cm78r6pjvcqjpptdjsjn585j

creation_rules:
  - path_regex: '.*\.yaml$'
    key_groups:
      - age:
          - *cortex
          - *orion
```

#### 3. Create Secrets File

```bash
# Create encrypted secrets file
cd ../nixos-secrets
sops secrets.yaml
```

**Example structure:**

```yaml
# secrets.yaml (encrypted)
jarvis:
  password_hash: $6$rounds=656000$...

# Add new secrets
api_keys:
  openai: sk-...
  github: ghp_...
```

#### 4. Create Nix Module

```nix
# nixos-secrets/default.nix
{ config, lib, pkgs, inputs, hasSecrets, ... }:

{
  # Only configure if secrets are present
  config = lib.mkIf hasSecrets {
    # SOPS configuration
    sops = {
      defaultSopsFile = ./secrets.yaml;
      defaultSopsFormat = "yaml";
      
      # Use SSH host key for decryption
      age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      
      # Define secrets
      secrets = {
        "jarvis/password_hash" = {
          neededForUsers = true;
        };
      };
    };
  };
}
```

#### 5. Use Secrets in Configuration

**System configuration:**

```nix
# systems/cortex/default.nix
users.users.jarvis = {
  hashedPasswordFile = lib.mkIf hasSecrets 
    config.sops.secrets."jarvis/password_hash".path;
};
```

**Home Manager:**

```nix
# homes/syg.nix
programs.git.extraConfig = {
  github.user = lib.mkIf hasSecrets
    (builtins.readFile config.sops.secrets."github/username".path);
};
```

---

## Common Operations

### Add New Secret

```bash
# 1. Edit secrets file
just edit-secrets

# 2. Add your secret in sops editor (vim by default)
# Save and exit (secrets auto-encrypted)

# 3. Commit to secrets repo
cd ../nixos-secrets
git add secrets.yaml
git commit -m "Add new API key"
git push  # if using remote repo

# 4. Update secret definition in default.nix
# nixos-secrets/default.nix
sops.secrets."api_keys/openai" = {};

# 5. Use in configuration
# systems/myhost/default.nix
environment.variables.OPENAI_API_KEY = 
  config.sops.secrets."api_keys/openai".path;

# 6. Deploy (secrets auto-sync)
just deploy-cortex
```

### Add New Host

```bash
# 1. Generate age key on new host
ssh newhost "sudo cat /etc/ssh/ssh_host_ed25519_key.pub" | ssh-to-age

# 2. Add to secrets repo
cd ../nixos-secrets
echo "age1..." > keys/hosts/newhost.txt

# 3. Update .sops.yaml
# Add &newhost anchor and include in creation_rules

# 4. Rekey all secrets
just rekey

# 5. Commit changes
git add .
git commit -m "Add newhost age key"
git push  # if using remote

# 6. Deploy to new host
just deploy-newhost
```

### Update Secret

```bash
# 1. Edit secrets
just edit-secrets

# 2. Modify value, save & exit

# 3. Commit changes
cd ../nixos-secrets
git add secrets.yaml
git commit -m "Update API key"

# 4. Deploy (auto-syncs secrets)
just deploy-cortex
```

### Rekey After Key Changes

```bash
# After adding/removing host keys
just rekey

# Verify all hosts can decrypt
cd ../nixos-secrets
for host in orion cortex; do
  echo "Testing $host..."
  sops --decrypt --extract '["jarvis"]["password_hash"]' secrets.yaml
done
```

---

## Strategy & Evolution

### Phase 1: Local + Auto-Sync (CURRENT) ✅

**Timeline:** Now - Month 3  
**Status:** ✅ Implemented

**Benefits:**
- ✅ Secrets automatically synced before EVERY deploy
- ✅ No manual steps to remember
- ✅ Version consistency across hosts
- ✅ Simple (no infrastructure changes needed)
- ✅ Works perfectly for 2-3 hosts

**When to Migrate:** When you hit one of these:
- Managing 5+ hosts (Proxmox, Frigate, Jellyfin, Home Assistant)
- Need to deploy from multiple locations
- Adding a second admin
- Want stronger disaster recovery

### Phase 2: Remote Git Repository (FUTURE)

**Timeline:** Month 3+  
**Status:** ⏳ Planned for homelab expansion

**Migration Path:**

```nix
# flake.nix (Phase 2)
inputs = {
  # From local...
  # nixos-secrets.url = "git+file:../nixos-secrets";
  
  # ...to self-hosted remote
  nix-secrets = {
    url = "git+ssh://git@homelab.local/nix-secrets.git?ref=main&shallow=1";
    inputs = { };
  };
};
```

**Options:**
1. **Self-hosted Gitea/Forgejo on Proxmox**
   - Full control, no external dependencies
   - Integrated with homelab
   - Backup to Synology

2. **Private GitLab** (EmergentMind's choice)
   - Professional features
   - External backup
   - Free tier available

3. **Self-hosted Gitea on Tailscale**
   - Secure remote access
   - No public exposure
   - Accessible anywhere

**Benefits of Remote:**
- ✅ Secrets version tied to flake.lock (deterministic)
- ✅ Rollback to old generation includes old secrets
- ✅ Can deploy from any location
- ✅ Better disaster recovery
- ✅ Easier team collaboration

**Setup Process:**

```bash
# 1. Set up Gitea on Proxmox
nix-shell -p gitea

# 2. Create nix-secrets repository
# 3. Push existing secrets
cd ../nixos-secrets
git remote add homelab git@homelab.local:nix-secrets.git
git push homelab main

# 4. Update flake.nix input
# 5. Test with just update-secrets
# 6. Deploy to all hosts
```

### Comparison: EmergentMind vs Your Setup

**EmergentMind's Approach:**

```nix
# flake.nix
inputs = {
  nix-secrets = {
    url = "git+ssh://git@gitlab.com/emergentmind/nix-secrets.git?ref=main&shallow=1";
    inputs = { };
  };
};
```

**Structure:**
```
nix-secrets/
├── .sops.yaml          # Creation rules and key anchors
├── sops/
│   ├── shared.yaml     # Secrets for ALL hosts
│   ├── ghost.yaml      # Host-specific secrets
│   ├── gusto.yaml
│   └── genoa.yaml
└── README.md
```

**Your Advantages:**
- ✅ Simpler (no remote git needed yet)
- ✅ Works well for 2-3 hosts
- ✅ Single secrets file easier to manage
- ✅ Automatic sync already implemented

**Missing (optional for future):**
- ❌ Per-host secrets files
- ❌ Remote git backup

---

## Troubleshooting

### Secret Not Decrypting

**Symptoms:** Activation fails with sops decryption error

**Solutions:**

1. **Check SSH host key exists:**
   ```bash
   ssh target-host "ls -l /etc/ssh/ssh_host_ed25519_key"
   ```

2. **Verify age key matches:**
   ```bash
   # On target
   ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub
   
   # Compare with nixos-secrets/keys/hosts/<hostname>.txt
   ```

3. **Rekey secrets:**
   ```bash
   just rekey
   ```

4. **Check sops configuration:**
   ```bash
   cd ../nixos-secrets
   sops --decrypt secrets.yaml
   ```

### Secrets Out of Sync

**Symptoms:** Deployed system has old secrets

**Solutions:**

1. **Manual sync:**
   ```bash
   just update-secrets
   ```

2. **Verify rebuild-pre hook:**
   ```bash
   # Check justfile has:
   rebuild-pre: update-secrets
   deploy-cortex: rebuild-pre
   ```

3. **Force flake update:**
   ```bash
   nix flake update nixos-secrets
   ```

### Cannot Edit Secrets

**Symptoms:** `sops` command fails or doesn't decrypt

**Solutions:**

1. **Check age key:**
   ```bash
   cat ~/.config/sops/age/keys.txt
   # Should contain your personal age key
   ```

2. **Export age key:**
   ```bash
   export SOPS_AGE_KEY_FILE=~/.config/sops/age/keys.txt
   ```

3. **Use correct sops command:**
   ```bash
   sops ../nixos-secrets/secrets.yaml
   ```

### Secrets Not Available at Build Time

**Symptoms:** System builds but secrets not accessible

**Solution:**

Mark secrets as `neededForUsers` if required during activation:

```nix
sops.secrets."user/password_hash" = {
  neededForUsers = true;
};
```

---

## Security Considerations

### Current Setup (Local Repo)

**Pros:**
- ✅ Secrets never leave your machine (until deployed)
- ✅ No remote server to compromise
- ✅ Full control over access

**Cons:**
- ⚠️ Single point of failure (your laptop)
- ⚠️ No off-site backup (until you add it)
- ⚠️ Can't deploy from other locations

**Mitigation:**
- Backup `../nixos-secrets` to Synology (encrypted)
- Store age keys separately (password manager)
- Regular backups of secrets repo

### Remote Repo (Future)

**Pros:**
- ✅ Off-site backup (built-in)
- ✅ Access from anywhere (with SSH key)
- ✅ Can recover if laptop dies

**Cons:**
- ⚠️ Remote server is attack surface
- ⚠️ Need to secure SSH access
- ⚠️ Requires server maintenance

**Mitigation:**
- Self-host on Tailscale (no public access)
- Use SSH key + passphrase
- Regular Gitea updates
- Firewall rules

---

## Resources

### Documentation
- [sops-nix GitHub](https://github.com/Mic92/sops-nix)
- [age Encryption](https://github.com/FiloSottile/age)
- [SOPS Documentation](https://github.com/mozilla/sops)

### Related Docs
- [docs/PROJECT-OVERVIEW.md](docs/PROJECT-OVERVIEW.md) - Overall architecture
- [FLEET-MANAGEMENT.md](FLEET-MANAGEMENT.md) - Deployment workflows
- [docs/IMPLEMENTATION-GUIDE.md](docs/IMPLEMENTATION-GUIDE.md) - Implementation guide

### EmergentMind's Approach
- [nix-secrets repo structure](https://github.com/EmergentMind/nix-config/tree/dev)
- [justfile with rebuild-pre](https://github.com/EmergentMind/nix-config/blob/dev/justfile)
- [Anatomy article](https://unmovedcentre.com/posts/anatomy-of-a-nixos-config/)

---

**Last Updated:** October 29, 2025  
**Phase:** 1 (Local + Auto-Sync) ✅ Implemented  
**Next Phase:** Remote git repo (when scaling to 5+ hosts)
