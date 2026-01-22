# Setting up Drone CI for Codeberg

This document provides a quick guide to set up a Drone CI instance to run the project's tests on Codeberg (self-hosted) or another Gitea/Git server.

Why Drone?
- Codeberg is a Gitea-based hosting platform; Drone is a popular, well-supported CI system for Gitea that integrates well with Codeberg.
- Drone supports Dockerized steps and can run arbitrary shell commands, which allows us to replicate the GitHub Actions pipeline.

## Example `.drone.yml`
This repository contains a sample `.drone.yml` that runs:
- `flake-check` - `nix flake check --show-trace` (ensures the flake builds)
- `templates-smoke` - `devenv-bootstrap --dry-run` for basic template checks
- `mirror-test` - `scripts/test-mirror.sh` to validate the mirror script

Customize the pipeline as needed to use more optimal images or caching mechanisms.

## Quick Drone server setup (Docker Compose)
This example shows a simple Docker Compose to run the Drone server and a runner.

1) Create `docker-compose.yml` (example):

```yaml
version: '3'
services:
  drone-server:
    image: drone/drone:2
    ports:
      - 8080:80
    restart: always
    environment:
      - DRONE_GITEA_SERVER=https://codeberg.org
      - DRONE_RPC_SECRET=YOUR_RANDOM_SECRET
      - DRONE_SERVER_HOST=drone.example.com
      - DRONE_SERVER_PROTO=https
      - DRONE_GITEA_CLIENT_ID=YOUR_GITEA_CLIENT_ID
      - DRONE_GITEA_CLIENT_SECRET=YOUR_GITEA_CLIENT_SECRET
    volumes:
      - ./data:/data

  drone-runner:
    image: drone/drone-runner-docker:1
    environment:
      - DRONE_RPC_PROTO=https
      - DRONE_RPC_HOST=drone.example.com
      - DRONE_RPC_SECRET=YOUR_RANDOM_SECRET
      - DRONE_RUNNER_CAPACITY=2
      - DRONE_RUNNER_NAME=runner-1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: always
```

2) Enable OAuth app in Codeberg (Gitea) and configure `DRONE_GITEA_CLIENT_ID` and `DRONE_GITEA_CLIENT_SECRET`.
3) Start the services:
```bash
docker-compose up -d
```
4) Configure Drone web UI to connect to Codeberg and activate the repository.

## Security
- Use strong `DRONE_RPC_SECRET` and do not store secrets in the repository.
- Configure the runner to run in an isolated environment and enforce least-privilege operations.

## Notes
- The sample `.drone.yml` uses `ubuntu:22.04` and installs Nix each run; you can switch to a Nix prebuilt image for better caching/performance.
- Drone has broad plugin options for caching and build optimization.

## Final step: Activate repo
- After getting a working Drone deployment, add the repo in Drone and configure webhooks on Codeberg (or let Drone do it).
- The pipeline will run on push/pull_request.
