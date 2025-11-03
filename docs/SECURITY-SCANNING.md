# Security Scanning Guide

**Last Updated:** November 2, 2025

This guide covers the secret scanning tools integrated into the NixOS dotfiles repository.

---

## 🔐 Available Tools

### git-secrets

**Purpose:** Prevent committing secrets to git repositories  
**Type:** Pre-commit hook + manual scanning  
**Status:** ✅ Active (pre-commit hook installed)

#### Features
- Prevents commits containing secrets
- Scans for AWS keys, passwords, tokens, SSH keys
- Runs automatically on every `git commit`
- Custom patterns for API keys, secrets, tokens

#### Usage

```bash
# Scan all files in the repository
git secrets --scan

# Scan a specific file
git secrets --scan path/to/file

# Scan git history (slower, thorough)
git secrets --scan-history

# List configured patterns
git secrets --list

# Add a custom pattern
git secrets --add 'pattern-regex'

# Add an allowed pattern (whitelist)
git secrets --add --allowed 'safe-pattern'

# Install hooks (already done via devenv)
git secrets --install
```

#### Configured Patterns

**Blocked Patterns:**
- AWS credentials (Access Key ID, Secret Access Key, Account ID)
- Passwords: `password = "actual-value"`
- API keys: `api-key = "value"`
- Secrets: `secret = "value"`
- Tokens: `token = "value"`
- SSH keys: `ssh-rsa`, `ssh-ed25519`

**Allowed Patterns (whitelisted):**
- `example.*password` - Example passwords in documentation
- `placeholder.*token` - Placeholder tokens
- `nixos@genesis` - Known safe identifier
- `your-wifi-password` - Template placeholder
- `password = "${syncPassword}"` - Nix variable references
- `password = "password"` - Default/placeholder value

---

### TruffleHog

**Purpose:** Deep scanning for secrets in git history  
**Type:** Manual/CI scanning tool  
**Status:** ✅ Available (version 3.90.9)

#### Features
- Scans entire git history
- Verifies secrets against live APIs
- Detects 700+ secret types
- High accuracy, low false positives

#### Usage

```bash
# Scan entire repository (verified secrets only)
trufflehog git file://. --only-verified

# Scan entire repository (including unverified)
trufflehog git file://.

# Scan specific branch
trufflehog git file://. --branch main

# Scan with JSON output
trufflehog git file://. --json

# Scan since a specific commit
trufflehog git file://. --since-commit <commit-hash>

# Scan a remote repository
trufflehog git https://github.com/user/repo.git

# Scan filesystem (not git)
trufflehog filesystem /path/to/scan
```

#### Best Practices

1. **Regular Scanning:** Run weekly or after major changes
2. **Pre-release Scan:** Always scan before making repository public
3. **Historical Scan:** Run full history scan periodically
4. **CI Integration:** Add to GitHub Actions or CI pipeline

#### Example Scan Results

```bash
# Last scan: November 2, 2025
trufflehog git file://. --only-verified
# Result: 2,207 chunks scanned
# Result: 0 verified secrets, 0 unverified secrets ✅
```

---

## 🔧 Quick Reference Commands

### Daily/Weekly Scans

```bash
# Quick scan (git-secrets)
git secrets --scan

# Deep scan (TruffleHog - verified only)
trufflehog git file://. --only-verified

# Full scan (TruffleHog - all findings)
trufflehog git file://.
```

### Before Making Repo Public

```bash
# Comprehensive scan with git-secrets
git secrets --scan-history

# Comprehensive scan with TruffleHog
trufflehog git file://. --json > trufflehog-report.json
```

### Fixing Found Secrets

If secrets are found:

1. **Rotate the secret immediately** (change password, regenerate API key)
2. **Remove from git history:**
   ```bash
   # Option 1: BFG Repo Cleaner (recommended)
   bfg --delete-files secret-file.txt
   
   # Option 2: git-filter-repo
   git filter-repo --invert-paths --path path/to/secret
   
   # Option 3: Interactive rebase (for recent commits)
   git rebase -i HEAD~10
   ```
3. **Force push** (if necessary and coordinated with team)
4. **Verify removal:**
   ```bash
   git secrets --scan-history
   trufflehog git file://. --only-verified
   ```

---

## 🚀 Automation

### Pre-commit Hook (Already Active)

Location: `.git/hooks/pre-commit` → `scripts/git-hooks/pre-commit`

```bash
#!/usr/bin/env bash
git secrets --pre_commit_hook -- "$@"
```

This hook runs automatically on every commit and blocks commits containing secrets.

### Manual Hook Installation

If the hook is missing or needs reinstallation:

```bash
# Install git-secrets hooks
git secrets --install

# Verify installation
ls -la .git/hooks/ | grep pre-commit
```

### CI/CD Integration (Future)

Example GitHub Actions workflow:

```yaml
name: Secret Scanning
on: [push, pull_request]

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      
      - name: TruffleHog Scan
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}
          head: HEAD
          extra_args: --only-verified
```

---

## 📊 Scan Status

### Current Status (November 2, 2025)

| Tool | Status | Last Scan | Findings |
|------|--------|-----------|----------|
| git-secrets | ✅ Active | Every commit | 0 secrets |
| TruffleHog | ✅ Available | Nov 2, 2025 | 0 verified secrets |

### Scan Schedule

- **git-secrets:** Automatic on every commit
- **TruffleHog:** Manual (recommended weekly)
- **Full history scan:** Monthly or before major releases

---

## 🛡️ Best Practices

1. **Never commit secrets:** Use SOPS, age encryption, or environment variables
2. **Use templates:** Store templates in `secrets-example/` directory
3. **Rotate immediately:** If a secret is committed, rotate it ASAP
4. **Scan before sharing:** Always scan before making repo public or sharing
5. **Review patterns:** Regularly update git-secrets patterns
6. **Monitor CI:** Add secret scanning to CI/CD pipeline
7. **Educate team:** Ensure all contributors know about these tools

---

## 📚 Related Documentation

- [SECURITY.md](./SECURITY.md) - Overall security configuration
- [SECRETS.md](../SECRETS.md) - Secret management with SOPS
- [devenv.nix](../devenv.nix) - Development environment setup

---

## 🔗 External Resources

- [git-secrets GitHub](https://github.com/awslabs/git-secrets)
- [TruffleHog GitHub](https://github.com/trufflesecurity/trufflehog)
- [SOPS Documentation](https://github.com/getsops/sops)
- [BFG Repo Cleaner](https://rtyley.github.io/bfg-repo-cleaner/)

---

**Notes:**
- Both tools are integrated into the devenv shell
- git-secrets runs automatically on every commit
- TruffleHog should be run manually for deep scans
- All patterns are configurable in `devenv.nix` shellHook
