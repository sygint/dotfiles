# Secrets Repository Template

This is an example structure for your private secrets repository that will be used as a git submodule.

## Setup

1. Create a new private repository (e.g., `nixos-secrets`)
2. Add this repo as a submodule to your main dotfiles:

```bash
cd /path/to/your/dotfiles
git submodule add git@github.com:yourusername/nixos-secrets.git secrets
```

## Structure

```
secrets/
├── .sops.yaml              # SOPS configuration
├── secrets.yaml            # Encrypted secrets
├── keys/
│   ├── age-key.txt         # Age private key
│   └── hosts/
│       ├── orion.txt       # Host-specific age key
│       └── cortex.txt        # Host-specific age key
├── default.nix             # Nix module to import
└── README.md               # This file
```

## Usage

The main flake will optionally import this if the submodule exists.
If it doesn't exist, the system will still build without secrets.
