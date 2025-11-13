# Security Scripts

Scripts for security scanning and secret detection.

## Scripts

### security-scan.sh
Comprehensive secret scanning with git-secrets and TruffleHog.

**Usage:**
```bash
./scripts/security/security-scan.sh [quick|full|history]
```

**Scan Modes:**

- `quick` (default) - Fast scan of current files
  ```bash
  ./scripts/security/security-scan.sh
  # or
  ./scripts/security/security-scan.sh quick
  ```
  - Scans staged and working directory files
  - Uses git-secrets patterns
  - Fast, suitable for pre-commit hooks
  - ~5-10 seconds

- `full` - Comprehensive scan including git history
  ```bash
  ./scripts/security/security-scan.sh full
  ```
  - Everything from quick scan
  - Full TruffleHog scan of entire git history
  - Checks all commits ever made
  - May take several minutes
  - Use before releases or periodic audits

- `history` - Git history scan only
  ```bash
  ./scripts/security/security-scan.sh history
  ```
  - TruffleHog scan of git history
  - Skips current file scans
  - For investigating past commits

**Exit Codes:**
- `0` - No secrets found
- `1` - Secrets detected
- `2` - Scan error

**Integration:**

The script is automatically called by:
- Git pre-commit hook (`scripts/git-hooks/pre-commit`)
- Git pre-push hook (`scripts/git-hooks/pre-push`)
- CI/CD pipelines (if configured)

**Manual Security Audit:**
```bash
# Quick check before commit
./scripts/security/security-scan.sh quick

# Full audit before release
./scripts/security/security-scan.sh full

# Check if secrets were ever committed
./scripts/security/security-scan.sh history
```

## Security Tools

The script uses:
- **git-secrets** - AWS Labs tool for preventing secrets in git
- **TruffleHog** - Scans for high-entropy strings and secrets

Both tools are available in the development environment via `devenv.nix`.

## Configuration

Secret patterns are configured in:
- `.git/config` - git-secrets patterns
- Local git-secrets configuration

To add custom patterns:
```bash
git secrets --add 'pattern-to-detect'
```

## Best Practices

1. **Run before every commit:** The pre-commit hook does this automatically
2. **Full scan periodically:** Run `security-scan.sh full` monthly
3. **Never disable checks:** If blocked, fix the issue, don't skip the hook
4. **Rotate if detected:** If a secret is found in history, rotate it immediately

## What's Detected

- API keys
- Passwords
- Private keys
- AWS credentials
- OAuth tokens
- Database connection strings
- High-entropy strings (potential secrets)
- Custom patterns

## If Secrets Are Found

1. **Don't commit!** Fix the issue first
2. **Remove the secret** from files
3. **Use environment variables** or secret management instead
4. **If in history:** Use `git filter-branch` or `BFG Repo-Cleaner`
5. **Rotate the secret** - assume it's compromised

## See Also
- [docs/SECURITY-SCANNING.md](../../docs/SECURITY-SCANNING.md) - Detailed documentation
- [docs/SECURITY.md](../../docs/SECURITY.md) - Security architecture
- [SECRETS.md](../../SECRETS.md) - Secret management guide
- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Development workflow
