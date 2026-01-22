{ pkgs, lib, config, inputs, ... }:

{
  env.GREET = "devenv";

  packages = with pkgs; [ 
    git
    curl
    jq
  ];

  languages.go = {
    enable = true;
    package = pkgs.go;
  };

  scripts.dev.exec = "go run .";
  scripts.build.exec = "go build";
  scripts.test.exec = "go test ./...";
  scripts.fmt.exec = "gofmt -w .";

  enterShell = ''
    echo "🐹 Go Development Environment"
    echo "============================="
    echo "📁 Project: $(basename $(pwd))"
    echo "🐹 Go: $(go version)"
    echo ""
    echo "🚀 Available scripts:"
    echo "  dev   - Run with go run"
    echo "  build - Build binary"
    echo "  test  - Run all tests"
    echo "  fmt   - Format code"
    echo ""
  '';

  # https://devenv.sh/pre-commit-hooks/
  # Uncomment to enable pre-commit hooks:
  # git-hooks.hooks.gofmt.enable = true;
  # git-hooks.hooks.golangci-lint.enable = true;
  # git-hooks.hooks.govet.enable = true;
}
