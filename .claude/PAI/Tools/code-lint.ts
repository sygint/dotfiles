#!/usr/bin/env bun
import { existsSync } from "fs";
import { join } from "path";
import { spawnSync } from "child_process";

function run(command: string, args: string[], cwd: string) {
  try {
    const r = spawnSync(command, args, { cwd, stdio: "inherit" });
    return r.status === 0;
  } catch (e) {
    console.warn(`Failed to run ${command}: ${String(e)}`);
    return false;
  }
}

function detectAndRun(repoRoot: string) {
  console.log(`Running code-lint in ${repoRoot}`);

  // JS/TS: eslint via npx if package.json present
  const pkg = join(repoRoot, "package.json");
  if (existsSync(pkg)) {
    console.log("-> Detected package.json — running eslint (npx --no-install eslint) if available");
    run("npx", ["--no-install", "eslint", "--ext", ".js,.ts,.tsx", "."], repoRoot);
  }

  // Go: golangci-lint
  const goMod = join(repoRoot, "go.mod");
  if (existsSync(goMod)) {
    console.log("-> Detected go.mod — running golangci-lint run if available");
    run("golangci-lint", ["run"], repoRoot);
  }

  // Shell scripts: run shellcheck on repository root .sh files
  try {
    run("sh", ["-c", "ls *.sh 2>/dev/null || true"], repoRoot);
    // best-effort: if shellcheck installed, run against repo root scripts
    run("shellcheck", ["-x", "*.sh"], repoRoot);
  } catch {}
}

const repoRoot = process.cwd();
detectAndRun(repoRoot);
