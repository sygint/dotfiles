# Contributing to NixOS Configuration

Thank you for contributing to this NixOS configuration! This guide will help you set up your development environment and understand the contribution process.

## 🚀 Quick Setup

Run this command to set up your development environment:

```bash
./scripts/setup-dev-environment.sh
```

This will:
- Install Git hooks for automatic validation
- Configure Git settings for Nix development
- Verify your Nix installation
- Test the configuration syntax

## 📋 Development Workflow

### 1. Making Changes

1. **Fork the repository** (if external contributor)
2. **Create a feature branch**: `git checkout -b feature/description`
3. **Make your changes** to the NixOS configuration
4. **Test locally**: `nix flake check`
5. **Commit your changes**: `git commit -m "description"`

### 2. Pre-commit Validation

Every commit is automatically validated with checks for:

- ✅ **Nix syntax and evaluation**
- ✅ **Code formatting** (tabs, trailing whitespace)
- ✅ **Security configuration** (firewall, SSH, etc.)
- ✅ **Secrets detection** (passwords, API keys)
- ✅ **Import validation** (missing files)
- ✅ **Large file detection**

### 3. Testing Changes

```bash
# Quick syntax check
nix flake check

# Full build test (slow but thorough)
NIXOS_VALIDATE_BUILD=true git commit

# Test specific configuration
nix build .#nixosConfigurations.nixos.config.system.build.toplevel --no-link

# Security audit
./scripts/security-audit.sh
```

## 🔧 Configuration Structure

```
├── systems/nixos/          # System-specific configurations
│   ├── default.nix         # Main system configuration
│   └── hardware.nix        # Hardware-specific settings
├── modules/                # Modular configurations
│   ├── nixos/             # NixOS system modules
│   └── home/              # Home Manager modules
├── dotfiles/              # Configuration files
├── scripts/               # Utility scripts
└── wallpapers/           # Desktop wallpapers
```

## 🛡️ Security Guidelines

This configuration includes comprehensive security hardening:

### VPN Configuration
- Set `settings.system.security.useVPN = true` when using VPN
- Set `settings.system.security.useVPN = false` for maximum security without VPN

### Security Features
- **Kernel hardening**: Memory protection, process restrictions
- **Network security**: Firewall, DNS over TLS (when not using VPN)
- **AppArmor**: Application sandboxing
- **Audit tools**: Built-in security scanning

### Security Checklist
- [ ] No hardcoded passwords or secrets
- [ ] Firewall remains enabled
- [ ] SSH properly configured (if enabled)
- [ ] Security modules remain active

## 🎯 Common Tasks

### Adding New Packages
```nix
environment.systemPackages = with pkgs; [
  # Add your package here
  your-package-name
];
```

### Creating New Modules
1. Create module in `modules/system/` or `modules/home/`
2. Add appropriate options with `mkOption`
3. Use `mkIf` for conditional configuration
4. Import in main configuration
5. **Namespace strategy:**
  - For custom modules, use the `modules.programs.<name>` namespace for options and config.
  - For upstream Home Manager modules, use the standard `programs.<name>` namespace for configuration.
  - This avoids collisions and keeps the configuration modular and future-proof.

### Modifying Security Settings
```nix
settings.system.security = {
  enable = true;
  kernelHardening = true;    # Kernel security
  networkHardening = true;   # Network security
  apparmor = true;          # Application sandboxing
  useVPN = true;            # VPN compatibility mode
};
```

## 🐛 Troubleshooting

### Bypassing Hooks (Emergency)
```bash
git commit --no-verify -m "emergency fix"
```

### Common Issues

**"Configuration fails to build"**
- Run `nix flake check` for detailed errors
- Check for syntax errors or missing imports

**"Git hooks not working"**
- Run `./scripts/setup-dev-environment.sh` again
- Check hook permissions: `ls -la .git/hooks/`

**"VPN not working after changes"**
- Ensure `useVPN = true` in security settings
- Check that DNS is not being overridden

## 📚 Resources

- [NixOS Manual](https://nixos.org/manual/nixos/stable/)
- [Nix Language Basics](https://nixos.org/manual/nix/stable/language/)
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Security Documentation](docs/security.md)

## 🤝 Getting Help

- **Issues**: Open a GitHub issue for bugs or feature requests
- **Security**: Report security issues privately
- **Questions**: Ask in discussions or issues

## 📝 Commit Guidelines

### Commit Message Format
```
type(scope): brief description

Longer explanation if needed
- Detail 1
- Detail 2
```

### Types
- `feat`: New feature or module
- `fix`: Bug fix
- `security`: Security-related changes
- `refactor`: Code restructuring
- `docs`: Documentation updates
- `style`: Formatting changes

### Examples
```
feat(security): add VPN-aware DNS configuration
fix(hyprland): resolve display scaling issues
security(firewall): strengthen network hardening
docs(contributing): add development setup guide
```

---

Thank you for helping improve this NixOS configuration! 🎉
