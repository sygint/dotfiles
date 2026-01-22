#!/usr/bin/env bash
# Test script for devenv-bootstrap
# Tests all templates to ensure they generate valid configurations

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR=$(mktemp -d)
BOOTSTRAP="$SCRIPT_DIR/devenv-bootstrap"
FAILURES=0
TESTS_RUN=0

cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

log_test() {
    echo -e "${BLUE}TEST:${NC} $1"
}

log_pass() {
    echo -e "${GREEN}✓ PASS${NC}: $1"
}

log_fail() {
    echo -e "${RED}✗ FAIL${NC}: $1"
    FAILURES=$((FAILURES + 1))
}

# Test helper: create project and run bootstrap
test_bootstrap() {
    local name="$1"
    local setup_fn="$2"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    log_test "$name"
    
    local test_dir="$TEST_DIR/$name"
    mkdir -p "$test_dir"
    cd "$test_dir"
    
    # Run setup function to create project files
    $setup_fn
    
    # Run bootstrap
    if ! "$BOOTSTRAP" --force . >/dev/null 2>&1; then
        log_fail "$name: bootstrap failed"
        return 1
    fi
    
    # Verify files were created
    if [[ ! -f devenv.nix ]] || [[ ! -f .envrc ]] || [[ ! -f devenv.yaml ]]; then
        log_fail "$name: missing output files"
        return 1
    fi
    
    # Verify devenv.nix syntax
    if ! nix-instantiate --parse devenv.nix >/dev/null 2>&1; then
        log_fail "$name: invalid Nix syntax in devenv.nix"
        return 1
    fi
    
    log_pass "$name"
}

# Test project setups
setup_generic() {
    touch README.md
}

setup_nodejs_default() {
    echo '{"name": "test", "version": "1.0.0"}' > package.json
}

setup_nodejs_volta() {
    echo '{"name": "test", "volta": {"node": "22.0.0"}}' > package.json
}

setup_nodejs_nvmrc() {
    echo '{"name": "test"}' > package.json
    echo 'v20.0.0' > .nvmrc
}

setup_python_main() {
    echo 'flask' > requirements.txt
    echo 'print("hello")' > main.py
}

setup_python_app() {
    echo 'flask' > requirements.txt
    echo 'print("hello")' > app.py
}

setup_python_pyproject() {
    cat > pyproject.toml << 'EOF'
[tool.poetry]
name = "test"
version = "0.1.0"
EOF
    echo 'print("hello")' > main.py
}

setup_rust() {
    cat > Cargo.toml << 'EOF'
[package]
name = "test"
version = "0.1.0"
edition = "2021"
EOF
}

setup_go() {
    cat > go.mod << 'EOF'
module test

go 1.21
EOF
}

# Run all tests
echo "Running devenv-bootstrap tests..."
echo "=================================="
echo ""

test_bootstrap "generic" setup_generic
test_bootstrap "nodejs-default" setup_nodejs_default
test_bootstrap "nodejs-volta" setup_nodejs_volta
test_bootstrap "nodejs-nvmrc" setup_nodejs_nvmrc
test_bootstrap "python-main" setup_python_main
test_bootstrap "python-app" setup_python_app
test_bootstrap "python-pyproject" setup_python_pyproject
test_bootstrap "rust" setup_rust
test_bootstrap "go" setup_go

# Test --dry-run flag
TESTS_RUN=$((TESTS_RUN + 1))
log_test "dry-run flag"
test_dir="$TEST_DIR/dry-run-test"
mkdir -p "$test_dir"
cd "$test_dir"
echo '{"name": "test"}' > package.json
if "$BOOTSTRAP" --dry-run . >/dev/null 2>&1 && [[ ! -f devenv.nix ]]; then
    log_pass "dry-run flag"
else
    log_fail "dry-run flag: should not create files"
fi

# Test --type flag
TESTS_RUN=$((TESTS_RUN + 1))
log_test "type flag"
test_dir="$TEST_DIR/type-flag-test"
mkdir -p "$test_dir"
cd "$test_dir"
if "$BOOTSTRAP" --force --type python . >/dev/null 2>&1 && grep -q "python" devenv.nix; then
    log_pass "type flag"
else
    log_fail "type flag: did not force python type"
fi

# Summary
echo ""
echo "=================================="
echo "Tests run: $TESTS_RUN"
if [[ $FAILURES -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Failures: $FAILURES${NC}"
    exit 1
fi
