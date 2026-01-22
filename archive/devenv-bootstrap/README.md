# devenv-bootstrap

> Smart project scaffolding for [devenv](https://devenv.sh) with automatic language detection and optimized configurations

## What is this?

`devenv-bootstrap` is a smarter alternative to `devenv init` that:

- 🔍 **Auto-detects** your project type (Node.js, Python, Rust, Go, etc.)
- 📦 **Reads version constraints** from `.nvmrc`, `package.json` (volta), etc.
- ⚡ **Pre-configures** sensible defaults (pnpm, scripts, git hooks)
- 🎯 **Generates production-ready** `devenv.nix` files instantly

> ⚠️ **Status:** Experimental — this project is not production-ready. Use with caution; keep production deployments separate.

## Why not just use `devenv init`?

| Feature | `devenv init` | `devenv generate` (AI) | **devenv-bootstrap** |
|---------|--------------|----------------------|---------------------|
| **Offline** | ✅ | ❌ Requires API | ✅ |
| **No code sent externally** | ✅ | ❌ Sends to AI | ✅ |
| **Project detection** | ❌ | ✅ | ✅ Smart heuristics |
| **Node version detection** | ❌ | Maybe | ✅ volta/.nvmrc |
| **Pre-configured scripts** | ❌ | Maybe | ✅ |
| **Package manager setup** | ❌ | Maybe | ✅ pnpm auto-install |
| **Instant** | ✅ | ❌ ~1 minute | ✅ |
| **Privacy** | ✅ | ❌ | ✅ |

## Installation

### With Nix (recommended)

```bash
# From Codeberg (recommended):
nix profile install git+ssh://git@codeberg.org/syg/devenv-bootstrap
```

### Direct download

```bash
# From Codeberg (SSH):
curl -fsSL https://codeberg.org/syg/devenv-bootstrap/raw/branch/main/devenv-bootstrap > devenv-bootstrap
# Or GitHub:
curl -fsSL https://raw.githubusercontent.com/sygint/devenv-bootstrap/main/devenv-bootstrap > devenv-bootstrap
chmod +x devenv-bootstrap
sudo mv devenv-bootstrap /usr/local/bin/
```

### From source

```bash
# Clone using SSH (Codeberg) (recommended):
git clone ssh://git@codeberg.org/syg/devenv-bootstrap.git
cd devenv-bootstrap
# Or HTTPS: (Codeberg)
# git clone https://codeberg.org/syg/devenv-bootstrap.git

sudo cp devenv-bootstrap /usr/local/bin/
sudo cp -r templates /usr/local/share/devenv-bootstrap/
```

## Usage

### Basic usage

```bash
# Bootstrap current directory
cd my-project
devenv-bootstrap

# Bootstrap specific directory
devenv-bootstrap ~/projects/myapp

# Force a specific type
devenv-bootstrap --type python .

# Preview without creating files
devenv-bootstrap --dry-run
```

### What gets created

```
your-project/
├── devenv.nix      # Optimized devenv configuration
├── devenv.yaml     # Input sources
├── .envrc          # direnv integration
└── .gitignore      # Updated with .devenv/
```

## Supported Project Types

### Node.js / TypeScript

**Detects:**
- `package.json` (with framework detection: Vite, Next.js, React)
- Node version from `.nvmrc` or `package.json` volta section
- Automatically configures the correct `nodejs_XX` package

**Includes:**
- pnpm with auto-install on shell enter
- Pre-configured scripts: `dev`, `build`, `lint`, `test`
- Optional git hooks: prettier, eslint, typos

**Example output:**
```nix
languages.javascript = {
  enable = true;
  package = pkgs.nodejs_20;  # Auto-detected from .nvmrc
  pnpm = {
    enable = true;
    install.enable = true;
  };
};
```

### Python

**Detects:**
- `requirements.txt` or `pyproject.toml`
- Common entry points: `main.py`, `app.py`, `run.py`

**Includes:**
- Poetry + pip support
- Pre-configured scripts: `dev`, `test`, `lint`
- Git hooks: black, flake8

### Rust

**Detects:**
- `Cargo.toml`

**Includes:**
- Stable Rust toolchain
- Cargo scripts: `dev`, `build`, `test`, `fmt`
- Git hooks: rustfmt, clippy

### Go

**Detects:**
- `go.mod`

**Includes:**
- Go toolchain
- Scripts: `dev`, `build`, `test`, `fmt`
- Optional git hooks: gofmt, golangci-lint, govet

### Generic

Falls back to a minimal template with:
- Basic Unix tools (git, curl, jq, make, gcc)
- ShellCheck git hook

## Options

```
-h, --help          Show help message
-f, --force         Overwrite existing files without prompting
-d, --dry-run       Preview what would be generated
-q, --quiet         Minimal output (for CI/automation)
-t, --type TYPE     Force project type (nodejs, python, rust, go, generic)
-v, --version       Show version information
```

## Examples

### Node.js project with version detection

```bash
$ cd my-vite-app
$ cat .nvmrc
v22.0.0

$ devenv-bootstrap
ℹ Bootstrapping devenv for: /home/user/my-vite-app
ℹ Detected project type: vite
ℹ Using Node.js 22 (nodejs_22) from .nvmrc
ℹ Creating devenv.nix...
ℹ Creating .envrc...
ℹ Creating devenv.yaml...
✓ devenv.nix created successfully!

ℹ Next steps:
  1. Run: direnv allow
  2. Next time you cd into this directory, the environment will auto-load!
```

### Python project

```bash
$ cd my-flask-app
$ devenv-bootstrap

ℹ Detected project type: python
ℹ Using Python entry point: app.py
✓ devenv.nix created successfully!
```

### Force specific type

```bash
$ devenv-bootstrap --type rust ~/projects/my-rust-cli
```

## Roadmap

- [ ] PHP support (Laravel, Symfony)
- [ ] Ruby support (Rails)
- [ ] Java support (Maven, Gradle)
- [ ] Service detection (auto-enable postgres, redis if detected in deps)
- [ ] Interactive mode (prompt for options)
- [ ] Custom template support (`~/.config/devenv-bootstrap/templates/`)
- [ ] Framework-specific optimizations (Next.js image optimization, etc.)

## CI & Hosting (if you want to run CI outside GitHub)

We recommend Codeberg as the canonical (primary) host. This repo includes a sample Drone CI (`.drone.yml`) and instructions in `docs/CI_DRONE.md` for running CI in Codeberg using Drone. You can mirror to GitHub if you still want to use GitHub Actions, but the idea here is to be able to run CI on Codeberg without relying on GitHub.

### PR & Issue mirroring

If you want contributors to open PRs or issues on GitHub (for convenience), we provide scripts to mirror PRs and issues to Codeberg so maintainers can review & merge there. See `scripts/mirror-pr-to-codeberg.sh` and `scripts/mirror-issue-to-codeberg.sh`.

We recommend:
- Use GitHub as a public read-only mirror and convenience interface.
- Use the CI (Drone) to run `./scripts/mirror-to-github.sh` on merges/tags to keep GitHub in sync.
- Use GitHub Actions as a convenience for early access; use Drone for authoritative CI and scheduled mirrors.

## Contributing

Contributions welcome! Areas that need help:

1. **More language templates** - Add support for PHP, Ruby, Java, etc.
2. **Better detection** - Improve framework/tool detection heuristics
3. **Service detection** - Auto-enable postgres/redis based on dependencies
4. **Tests** - Add test suite for detection logic

## License

MIT - see [LICENSE](LICENSE)

## Credits

Created by [@sygint](https://github.com/sygint) as a smarter alternative to `devenv init`.

Built with ❤️ for the [devenv](https://devenv.sh) community.
