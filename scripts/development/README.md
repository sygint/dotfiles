# Development Scripts

Scripts for setting up and managing the development environment.

## Scripts

### setup-dev-environment.sh
Sets up the complete development environment including git hooks, security tools, and shell configuration.

**Usage:**
```bash
./scripts/development/setup-dev-environment.sh
```

**What it sets up:**
- Git hooks (pre-commit, pre-push)
- Security scanning tools
- Shell integrations
- Development dependencies
- Project structure validation

**First-time setup:**
```bash
cd ~/.config/nixos
./scripts/development/setup-dev-environment.sh
```

### dev-shell.sh
Launches a development shell with all necessary tools and environment variables.

**Usage:**
```bash
./scripts/development/dev-shell.sh [target-directory]
```

**Example:**
```bash
# Start dev shell in current directory
./scripts/development/dev-shell.sh

# Start dev shell in specific directory
./scripts/development/dev-shell.sh ~/projects/myapp
```

### update_antidote_plugins.sh
Updates Zsh plugins managed by Antidote.

**Usage:**
```bash
./scripts/development/update_antidote_plugins.sh
```

**Alias:** `update_plugins` (when in dev environment)

**What it does:**
- Updates all Antidote-managed plugins
- Refreshes plugin cache
- Validates plugin installations

## Development Workflow

1. **Initial Setup:**
   ```bash
   ./scripts/development/setup-dev-environment.sh
   ```

2. **Enter Dev Environment:**
   ```bash
   direnv allow  # If using direnv
   # or
   nix develop  # Manual activation
   ```

3. **Update Plugins (as needed):**
   ```bash
   update_plugins
   ```

## Git Hooks

The setup script installs git hooks that:
- Run security scans before commit (pre-commit)
- Validate code before push (pre-push)
- Prevent committing secrets

Hooks are located in `scripts/git-hooks/` and symlinked to `.git/hooks/`.

## See Also
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contribution guidelines
- [devenv.nix](../../devenv.nix) - Development environment configuration
- [docs/SECURITY-SCANNING.md](../../docs/SECURITY-SCANNING.md) - Security tool documentation
