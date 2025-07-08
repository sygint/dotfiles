# Development Environments

This configuration includes support for [devenv](https://devenv.sh/), a fast and declarative development environment manager.

## Quick Start with devenv

1. **Navigate to a project directory**:
   ```bash
   mkdir my-project && cd my-project
   ```

2. **Initialize devenv**:
   ```bash
   devenv init
   ```

3. **Edit `devenv.nix`** to configure your development environment

4. **Create `.envrc`**:
   ```bash
   echo "use devenv" > .envrc
   direnv allow
   ```

## devenv Features Available

- **Language support**: Python, Node.js, Go, Rust, and more
- **Services**: PostgreSQL, Redis, databases, etc.
- **Pre-commit hooks**: Automatic linting and formatting
- **Scripts**: Custom development commands
- **Process management**: Run multiple services
- **Testing**: Automated environment testing

## Comparison with Traditional Flakes

| Feature | Traditional `flake.nix` | devenv |
|---------|-------------------------|--------|
| **Learning curve** | Steep | Gentle |
| **Configuration** | Complex | Declarative & simple |
| **Services** | Manual setup | Built-in service management |
| **Pre-commit** | Manual integration | Automatic setup |
| **Processes** | External tools needed | Built-in process manager |
| **Speed** | Fast | Very fast with caching |

## Example Templates

### Node.js/TypeScript Project

Create a `devenv.nix` file in your project directory:

```nix
{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  env.GREET = "devenv";

  # https://devenv.sh/packages/
  packages = with pkgs; [ 
    git
    nodejs_22
    nodePackages.pnpm
    nodePackages.typescript
    nodePackages.typescript-language-server
  ];

  # https://devenv.sh/scripts/
  scripts = {
    hello.exec = "echo hello from $GREET";
    dev.exec = "pnpm dev";
    build.exec = "pnpm build";
    test.exec = "pnpm test";
  };

  enterShell = ''
    hello
    echo "Node.js $(node --version)"
    echo "pnpm $(pnpm --version)"
    echo ""
    echo "Available scripts:"
    echo "  dev   - Start development server"
    echo "  build - Build for production"
    echo "  test  - Run tests"
  '';

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    node --version | grep --color=auto "${pkgs.nodejs_22.version}"
  '';

  # https://devenv.sh/services/
  # services.postgres.enable = true;

  # https://devenv.sh/languages/
  languages.javascript = {
    enable = true;
    package = pkgs.nodejs_22;
    npm.enable = false;  # We use pnpm instead
  };

  # https://devenv.sh/pre-commit-hooks/
  pre-commit.hooks = {
    eslint.enable = true;
    prettier.enable = true;
    # nil.enable = true;  # Only enable if you have multiple Nix files in your project
  };

  # https://devenv.sh/processes/
  # processes.dev.exec = "pnpm dev";

  # See full reference at https://devenv.sh/reference/options/
}
```

### Python Project

Create a `devenv.nix` file in your project directory:

```nix
{ pkgs, ... }:

{
  # https://devenv.sh/basics/
  env = {
    GREET = "Python devenv";
    PYTHONPATH = "./src";
  };

  # https://devenv.sh/packages/
  packages = with pkgs; [ 
    git
    python312
    python312Packages.pip
    python312Packages.virtualenv
    ruff  # Fast Python linter
    black # Code formatter
  ];

  # https://devenv.sh/scripts/
  scripts = {
    hello.exec = "echo hello from $GREET";
    dev.exec = "python src/main.py";
    test.exec = "python -m pytest tests/";
    lint.exec = "ruff check . && black --check .";
    format.exec = "black . && ruff check . --fix";
  };

  enterShell = ''
    hello
    echo "Python $(python --version)"
    echo "pip $(pip --version)"
    echo ""
    echo "Available scripts:"
    echo "  dev    - Run main.py"
    echo "  test   - Run tests with pytest"
    echo "  lint   - Check code with ruff and black"
    echo "  format - Format code with black and fix ruff issues"
  '';

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running tests"
    python --version | grep --color=auto "${pkgs.python312.version}"
  '';

  # https://devenv.sh/languages/
  languages.python = {
    enable = true;
    package = pkgs.python312;
    venv = {
      enable = true;
      requirements = ''
        requests
        fastapi
        uvicorn
        pytest
        black
        ruff
      '';
    };
  };

  # https://devenv.sh/pre-commit-hooks/
  pre-commit.hooks = {
    black.enable = true;
    ruff.enable = true;
    nil.enable = true;  # Nix linter
  };

  # https://devenv.sh/processes/
  # processes.api.exec = "uvicorn main:app --reload";

  # See full reference at https://devenv.sh/reference/options/
}
```

## Using DevEnv Templates

1. Create a `devenv.nix` file in your project (use examples above)
2. Create a `.envrc` file with: `use devenv`
3. Run `direnv allow` to activate the environment
4. The development environment will automatically load when you enter the directory
