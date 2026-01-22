# Mirror to GitHub

This project is canonical on Codeberg. If you want to use GitHub Actions for CI, you can mirror the repository to GitHub. This is optional but makes it easy to use GitHub Actions without setting up a Codeberg CI runner.

## Quick Steps (manual)

1. Create the GitHub repo (either via GitHub UI or `gh`):

```bash
# Create remote on GitHub using gh (requires gh auth login)
gh repo create syg/devenv-bootstrap --public --source=. --remote=github --push

# Or create repo in GitHub UI and add remote:
git remote add github git@github.com:syg/devenv-bootstrap.git
git push -u github main
git push github --tags
```

2. Mirror trunk & tags

```bash
# Push the main branch and tags to GitHub
git push -u github main
git push --tags github
```

3. Set up CI (optional)

- The flake already has `ci.yml` under `.github/workflows/` which will run on GitHub.
- If you prefer Codeberg-only CI, set up Drone or a similar runner.

## Automated script (local)

There is a helper script in `scripts/mirror-to-github.sh` that will:

- Add a `github` remote if missing
- Optionally create the GitHub repo using `gh` when `--create-repo` is passed
- Push `main` and tags
- Create a GitHub release for `v2.1.0` if `gh` is installed

Usage:

```bash
# Dry run (help)
./scripts/mirror-to-github.sh --help

# Create GitHub repo and push
./scripts/mirror-to-github.sh --create-repo --visibility public
```

## Notes

- The script will not try to create a GitHub repo unless `--create-repo` is passed.
- If `gh` is missing, the script will provide instructions for manual steps.
- Keep Codeberg as the canonical remote to preserve privacy and control; use GitHub as a CI mirror.
