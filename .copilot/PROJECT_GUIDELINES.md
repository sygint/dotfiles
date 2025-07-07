# Project Guidelines for GitHub Copilot

## Core Principles
- **I execute commands** - No asking you to run `nh home switch`, `git status`, etc. and paste output
- **I analyze output** - Success/failure analysis to determine next steps
- **I maintain context** - No repeating info I should already have
- **Notify manual changes** - Quick "I've updated `file.nix`" is perfect
- **No interactive tools** - Never launch `nix repl`, `vim`, etc. without explicit instructions
- **Always check actual state** - Use `git status`, `ls`, etc. instead of assuming what exists
- **Verify working tree** - Always check git status when working with commits, debugging, testing
- **Cohesive commits** - Each commit should be logical and focused, split unrelated changes

## Current Focus
- **Live-update symlinks** - Implement `mkOutOfStoreSymlink` pattern for dotfiles
- **Extend pattern** - Apply to kitty, btop, and other applications  
- **Workflow** - Maintain declarative management + live editing capability
- **Tools** - Use `nh os switch` and `nh home switch` for system management

## Debugging Process
1. `nix flake check -L` for syntax/reference errors
2. `nix build .#syg -L --show-trace` to isolate build issues
3. `nix repl .` for complex evaluations (with explicit commands)
4. `journalctl` for runtime service failures
5. Comment out recent changes to bisect problems

## Code Quality
- Format with `nixpkgs-fmt`
- Lint with `statix check` 
- Remove dead code with `deadnix`
- Test with `nh home switch` after changes