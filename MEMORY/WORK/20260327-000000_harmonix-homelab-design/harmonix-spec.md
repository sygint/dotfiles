# Harmonix - Homelab Management Tool

## Overview

Harmonix is a Nix-first homelab management tool that handles secrets management, configuration deployment, and orchestration across multiple machines. It follows a flake-centric architecture with pull-based updates as the default, and push capability for emergencies.

**Design Philosophy:**
- Security-first: Don't screw up credential rotation
- Dogfood from day 1: Build the tool while using it
- Community-minded: Public configs, private secrets, modular design

---

## Architecture

### High-Level Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        HARMONIX                                 │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────────┐  │
│  │   CLI/UI     │  │  Secrets     │  │   Orchestrator       │  │
│  │  (harmonix)  │  │  Manager     │  │   (pull/push)       │  │
│  └──────────────┘  └──────────────┘  └──────────────────────┘  │
│         │                  │                     │            │
│         └──────────────────┼─────────────────────┘            │
│                            │                                   │
│                    ┌───────▼───────┐                          │
│                    │   State Store │                          │
│                    │  (git-backed)  │                          │
│                    └───────────────┘                          │
└─────────────────────────────────────────────────────────────────┘

     │                    │                     │
     ▼                    ▼                     ▼
┌─────────┐         ┌─────────┐          ┌─────────┐
│ Private │         │ Public  │          │ Machines│
│  Repo   │         │  Repo   │◄─────────│ (pull)  │
│ (secrets│◄───────►│(configs)│          └────┬────┘
│ + keys) │         │         │               │
└─────────┘         └─────────┘          ┌─────▼────┐
                                         │ (push)   │
                                         └──────────┘
```

### Core Components

#### 1. Secrets Manager
- **Purpose**: Handle all secret lifecycle (create, assign, verify, rotate, rollback)
- **Integration**: Wraps sops-nix + age-nix
- **Operations**:
  - `harmonix secret create <name> [--group=<group>] [--machine=<machine>]`
  - `harmonix secret assign <secret> <target>`
  - `harmonix secret verify <secret>` - validates format and test connectivity
  - `harmonix secret rotate <secret> [--backup]`
  - `harmonix secret rollback <secret> <version>`

#### 2. Orchestrator
- **Pull Mode**: Machines run `harmonix pull` via cron/systemd timer
- **Push Mode**: `harmonix push <machine> [--force]` for emergencies
- **Signed Flakes**: Uses Nix flake signatures for verification
- **Rollback**: Maintains last N known-good configurations

#### 3. Machine Registry
- **Purpose**: Track all managed machines, their roles, and configs
- **State**: Stored in private repo as YAML/JSON
- **Fields per machine**:
  - `hostname`: Machine name
  - `role`: ci-runner, pihole, builder, etc.
  - `tier`: global, type-specific, per-machine
  - `secrets`: list of secret names
  - `flake-input`: which flake input provides config

#### 4. State Store
- **Git-backed**: Private repo at `git@github.com:user/harmonix-secrets.git`
- **Structure**:
  ```
  harmonix-secrets/
  ├── machines.yaml          # Machine registry
  ├── secrets/
  │   ├── global/           # Shared across all machines
  │   ├── types/            # By role/type (ci-runner, pihole, etc)
  │   └── <hostname>/       # Machine-specific
  ├── keys/
  │   └── age/               # age keys per machine
  └── .sops.yaml             # sops configuration
  ```

---

## Secrets Strategy: Tiered Approach

### Three Tiers

| Tier | Scope | Use Case |
|------|-------|----------|
| **Global** | All machines | WiFi passwords, VPN keys, GitHub tokens |
| **Type/Role** | Machines of same role | CI runner credentials, Pihole DNS keys |
| **Per-machine** | Single machine | Root passwords, unique API keys |

### Secrets Lifecycle

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│ Create  │───►│ Assign  │───►│ Verify  │───►│ Deploy  │
└─────────┘    └─────────┘    └─────────┘    └─────────┘
     │                                        │
     │          ┌─────────┐                  │
     └─────────►│ Rotate  │──────────────────┴──►
                └─────────┘    (verify after each step)
```

**Verification Steps:**
1. Secret format validation (age key format, password length, etc.)
2. Dry-run deployment (can nixos-rebuild --dry-build)
3. Service health check (does the service start with new secret?)
4. Rollback capability confirmed

---

## Machine Lifecycle

### 1. Provisioning (Push)
```
┌────────────────┐
│ Boot NixOS USB│
└──────┬─────────┘
       │
       ▼
┌──────────────────┐
│ Run harmonix     │
│ init --push      │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ SSH with root    │
│ key + age key    │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Clone private    │
│ repo + decrypt   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Apply NixOS     │
│ config          │
└──────────────────┘
```

### 2. Ongoing Updates (Pull)
```
┌──────────────┐
│ Cron/timer   │
│ triggers     │
│ harmonix pull│
└──────┬───────┘
       │
       ▼
┌──────────────────┐
│ git pull origin  │
│ main             │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Validate changes │──► If signed OK
│ (flake check)   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ nixos-rebuild   │
│ switch --flake   │
└──────┬───────────┘
       │
       ▼
┌──────────────────┐
│ Health check     │
└──────────────────┘
```

### 3. Decommissioning
```
harmonix machine decomission <hostname>
  → Remove from machines.yaml
  → Revoke age key
  → Archive secrets (don't delete!)
  → Remove from CI/SSH known_hosts
```

---

## Repository Structure

### Public Repo: `nixos-config`
```
nixos-config/
├── flake.nix
├── hosts/
│   ├── gaming-12700k/
│   │   └── default.nix
│   ├── homelab-5900x/
│   │   └── default.nix
│   ├── homelab-3600x/
│   ├── worker-6500t/
│   └── worker-8500t/
├── modules/
│   ├── common/           # Shared across all
│   ├── pihole/
│   ├── ci-runner/
│   └── ...
├── lib/
│   └── ...
└── README.md
```

### Private Repo: `harmonix-secrets`
```
harmonix-secrets/
├── .sops.yaml            # sops config
├── machines.yaml         # Machine registry
├── hosts.yaml           # Host-specific configs
├── flake.nix            # Generates secrets as flake outputs
├── age/
│   ├── admin.pub        # Admin age key (for recovery)
│   ├── gaming-12700k.age
│   ├── homelab-5900x.age
│   └── ...
└── secrets/
    ├── global/          # Decrypts to all machines
    │   ├── wireguard.sops
    │   └── github-token.sops
    ├── ci-runner/      # Decrypts to CI machines
    │   └── runner-token.sops
    └── <hostname>/     # Per-machine
        └── root-password.sops
```

---

## Implementation Phases

### Phase 1: Secrets Management (MVP)
**Goal**: Get secrets CRUD + rotation working, prove it with verification

**Scope:**
- [ ] Harmonix CLI skeleton
- [ ] Machine registry (machines.yaml)
- [ ] Secrets create/assign/verify
- [ ] Secrets rotate with backup
- [ ] Secrets rollback
- [ ] Integration with sops-nix/age-nix
- [ ] Verification workflow (dry-run, test, rollback)

**Deliverable**: Can manage secrets for 1 test machine without breaking things

**Dogfood**: Use harmonix to manage secrets for harmonix itself

### Phase 2: Pull-Based Deployment
**Goal**: Machines can pull configs from private repo

**Scope:**
- [ ] Git-based pull mechanism
- [ ] Per-machine age key deployment
- [ ] Flake-signed configs
- [ ] `harmonix pull` command
- [ ] Health check after pull
- [ ] Auto-update timer/cron

**Deliverable**: Machines update automatically on git push

### Phase 3: Push Capability
**Goal**: Emergency push when pull isn't available

**Scope:**
- [ ] SSH-based push
- [ ] Signed flake verification before push
- [ ] Force push for emergency
- [ ] Initial provisioning flow
- [ ] Offline provisioning (USB-based)

**Deliverable**: Can fix machine that's offline or broken

### Phase 4: CI/CD Integration
**Goal**: Full pipeline for homelab

**Scope:**
- [ ] Gitea/GitHub Actions integration
- [ ] Test configs before deploy
- [ ] Multi-machine orchestration
- [ ] Backup/restore workflows
- [ ] Monitoring integration

---

## Verification Strategy

Before trusting harmonix with real secrets:

1. **Format Validation**: `harmonix secret verify` checks age key format, password length, etc.
2. **Dry-Run Deploy**: `nixos-rebuild --dry-build` proves config parses
3. **Service Test**: Start service with new secret in staging mode
4. **Rollback Ready**: `harmonix secret rollback` can restore previous version
5. **Audit Log**: All secrets operations logged with timestamps

---

## Authentication

### Pull (Machine → Git)
- Deploy key with read-only access to private repo
- Per-machine deploy key (can revoke individually)
- SSH key-based auth

### Push (Admin → Machine)
- Admin's SSH key with root access
- Age key verification for signed flakes

### Secrets Access
- Age keys: One per machine + admin recovery key
- SOPS: .sops.yaml defines who can decrypt what

---

## Community Contribution Path

The public repo (`nixos-config`) should be:
- Modular: Common modules that work across setups
- Documented: README for each module
- Flake-friendly: Proper flake inputs/outputs
- Non-secret: No hardcoded secrets, use references

Example contribution:
```nix
# In user's flake.nix
inputs.harmonix-modules.url = "github:user/nixos-config";
inputs.harmonix-modules.inputs.nixpkgs.follows = "nixpkgs";

# Use module
imports = [ harmonix-modules.modules.pihole ];
```

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Lost admin key | Print recovery key on setup, store in physical safe |
| Machines can't pull | Push capability as fallback |
| Secret rotation breaks service | Full verification before deploy, quick rollback |
| Repo unavailable | Local cache of last known-good config |
| Accidental secret deletion | Archive instead of delete, git history |

---

## Next Steps

1. **Start Phase 1**: Set up harmonix CLI, machines.yaml, basic secrets CRUD
2. **Test on one machine**: Use harmonix to manage its own secrets
3. **Verify works**: Prove secrets rotation doesn't break things
4. **Expand**: Add more machines, move to pull-based deployment
