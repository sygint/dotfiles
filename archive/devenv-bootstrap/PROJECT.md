# devenv-bootstrap Project

## Created: 2025-11-20

### Location
`~/projects/devenv-bootstrap/`

### What is it?
A standalone tool that provides smart project scaffolding for devenv with automatic language detection. It's the extracted, polished version of the bootstrap script from your NixOS dotfiles.

### Project Structure
```
devenv-bootstrap/
├── devenv-bootstrap          # Main executable script
├── flake.nix                 # Nix flake for installation
├── README.md                 # Comprehensive documentation
├── LICENSE                   # MIT license
├── .gitignore               # Git ignore file
└── templates/               # Template files
    ├── nodejs.nix           # Node.js template with version detection
    ├── python.nix           # Python template
    ├── rust.nix             # Rust template
    ├── go.nix               # Go template
    └── generic.nix          # Generic fallback template
```

### Key Features
- **Smart Detection**: Auto-detects project type from files (package.json, Cargo.toml, etc.)
- **Version Detection**: Reads Node.js versions from .nvmrc or package.json volta section
- **Template-based**: Clean separation of logic and templates
- **Nix Flake**: Can be installed with `nix profile install`
- **Zero Dependencies**: Pure bash, only needs standard Unix tools

### Installation Options

1. **Nix Flake (once published to Codeberg or GitHub)**:
   ```bash
   # From Codeberg (recommended):
   nix profile install git+ssh://git@codeberg.org/syg/devenv-bootstrap

   # Or GitHub (optional):
   nix profile install github:sygint/devenv-bootstrap
   ```

2. **Local testing**:
   ```bash
   nix build ~/projects/devenv-bootstrap
   ./result/bin/devenv-bootstrap
   ```

3. **Direct use**:
   ```bash
   ~/projects/devenv-bootstrap/devenv-bootstrap --help
   ```

### Next Steps

1. **Test thoroughly**:
   - Test with Node.js projects (with .nvmrc, with volta, without)
   - Test with Python projects
   - Test with Rust/Go projects
   - Test all CLI flags

2. **Create repository**:
   ```bash
   # Create repo on Codeberg using the web UI or via API
   # Push to Codeberg (SSH):
   git remote add origin ssh://git@codeberg.org/syg/devenv-bootstrap.git
   git push -u origin main
   ```

3. **Add to your dotfiles** (optional):
   - Link it from your NixOS config as a flake input
   - Or just use `nix profile install` to install it globally

4. **Share with the community**:
   - Post on NixOS Discourse
   - Share on Reddit r/NixOS
   - Tweet about it
   - Submit to awesome-nix lists

### Differences from Original Script

**Improvements**:
- ✅ Templates extracted to separate files (maintainable)
- ✅ Proper Nix flake for installation
- ✅ Creates `devenv.yaml` in addition to `devenv.nix`
- ✅ Better .gitignore handling (includes .direnv and devenv.lock)
- ✅ Professional README with comparison table
- ✅ MIT license
- ✅ Version bumped to 2.1.0

**Kept**:
- ✅ All detection logic (Node.js versions, Python entrypoints, etc.)
- ✅ CLI interface (--dry-run, --force, --type, etc.)
- ✅ Pretty colored output
- ✅ Smart defaults for each language

### Development Workflow

```bash
# Edit templates
vim ~/projects/devenv-bootstrap/templates/nodejs.nix

# Edit main script
vim ~/projects/devenv-bootstrap/devenv-bootstrap

# Test locally
~/projects/devenv-bootstrap/devenv-bootstrap --dry-run

# Build with Nix
cd ~/projects/devenv-bootstrap
nix build

# Test built version
./result/bin/devenv-bootstrap --help

# Commit changes
git add .
git commit -m "feat: add XYZ"
```

### Future Enhancements

See README.md Roadmap section:
- PHP support
- Ruby support  
- Java support
- Service detection (postgres, redis)
- Interactive mode
- Custom template support
- Framework-specific optimizations

### Maintenance

- Keep templates in sync with devenv best practices
- Update Node.js version mappings as new versions release
- Monitor devenv changes that might require template updates
