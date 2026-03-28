#!/usr/bin/env bun
import { existsSync, readdirSync, readFileSync } from "fs";
import { join } from "path";
import { spawnSync } from "child_process";

type ToolResult = {
  tool: string;
  ok: boolean;
  exitCode: number | null;
  errors: number;
  warnings: number;
  stdout: string;
  stderr: string;
  note?: string;
};

function runCapture(command: string, args: string[], cwd: string): ToolResult {
  try {
    const r = spawnSync(command, args, { cwd, encoding: "utf-8" as any, shell: false });
    const stdout = (r.stdout || "") as string;
    const stderr = (r.stderr || "") as string;
    const out = `${stdout}\n${stderr}`.trim();
    // Naive counts
    const errors = (out.match(/error/gi) || []).length;
    const warnings = (out.match(/warning/gi) || []).length;
    return {
      tool: [command, ...(args || [])].join(" "),
      ok: r.status === 0,
      exitCode: r.status === null ? -1 : r.status,
      errors,
      warnings,
      stdout,
      stderr,
    };
  } catch (e) {
    return {
      tool: command,
      ok: false,
      exitCode: -1,
      errors: 1,
      warnings: 0,
      stdout: "",
      stderr: String(e),
    };
  }
}

function readJSON(file: string) {
  try {
    return JSON.parse(readFileSync(file, "utf-8"));
  } catch {
    return null;
  }
}

function detectTools(repoRoot: string) {
  const detected = new Set<string>();
  const pkgPath = join(repoRoot, "package.json");
  if (existsSync(pkgPath)) {
    detected.add("node");
    const pkg = readJSON(pkgPath) || {};
    const deps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };
    if (deps.eslint || existsSync(join(repoRoot, ".eslintrc.js")) || existsSync(join(repoRoot, ".eslintrc.json"))) detected.add("eslint");
    if (deps.prettier || existsSync(join(repoRoot, ".prettierrc")) || existsSync(join(repoRoot, "prettier.config.js"))) detected.add("prettier");
    if (pkg.scripts && pkg.scripts.test) detected.add("npm-test");
  }

  if (existsSync(join(repoRoot, "pyproject.toml")) || existsSync(join(repoRoot, "requirements.txt"))) {
    detected.add("python");
    // optimistic
    detected.add("pytest");
    detected.add("black");
    detected.add("ruff");
  }

  if (existsSync(join(repoRoot, "go.mod"))) {
    detected.add("go");
    detected.add("golangci-lint");
  }

  if (existsSync(join(repoRoot, "Cargo.toml"))) {
    detected.add("rust");
  }

  // shell scripts
  const files = readdirSync(repoRoot).filter(f => f.endsWith('.sh'));
  if (files.length > 0) detected.add("shellcheck");

  return Array.from(detected);
}

function runChecks(repoRoot: string, opts: { fix: boolean; format: string; ci: boolean }) {
  const results: ToolResult[] = [];
  const detected = detectTools(repoRoot);

  // Node/JS checks
  const pkgPath = join(repoRoot, "package.json");
  if (existsSync(pkgPath)) {
    const pkg = readJSON(pkgPath) || {};
    const deps = { ...(pkg.dependencies || {}), ...(pkg.devDependencies || {}) };

    if (deps.eslint || existsSync(join(repoRoot, ".eslintrc.js")) || existsSync(join(repoRoot, ".eslintrc.json"))) {
      const args = ["--no-install", "eslint", "--ext", ".js,.ts,.tsx", "."];
      if (opts.fix) args.push("--fix");
      results.push(runCapture("npx", args, repoRoot));
    }

    if (deps.prettier || existsSync(join(repoRoot, ".prettierrc")) || existsSync(join(repoRoot, "prettier.config.js"))) {
      const args = ["--no-install", "prettier", "--check", "."];
      if (opts.fix) args[1] = "prettier"; // still use npx prettier --write when --fix
      if (opts.fix) results.push(runCapture("npx", ["--no-install", "prettier", "--write", "."], repoRoot));
      else results.push(runCapture("npx", args, repoRoot));
    }

    // run tests if script exists
    if ((pkg.scripts && pkg.scripts.test) || deps.jest || deps.mocha || deps.vitest) {
      // prefer npm test for scripts
      if (pkg.scripts && pkg.scripts.test) {
        results.push(runCapture("npm", ["test", "--silent"], repoRoot));
      } else {
        // try jest
        if (deps.jest) results.push(runCapture("npx", ["--no-install", "jest", "--bail"], repoRoot));
      }
    }
  }

  // Python checks (best-effort)
  if (existsSync(join(repoRoot, "pyproject.toml")) || existsSync(join(repoRoot, "requirements.txt"))) {
    // ruff (linter + autofix)
    const ruffArgs = ["check", "."];
    if (opts.fix) ruffArgs.unshift("--fix");
    results.push(runCapture("ruff", ruffArgs, repoRoot));
    // black
    if (opts.fix) results.push(runCapture("black", ["."], repoRoot));
    else results.push(runCapture("black", ["--check", "."], repoRoot));
    // pytest
    results.push(runCapture("pytest", ["-q"], repoRoot));
  }

  // Go
  if (existsSync(join(repoRoot, "go.mod"))) {
    results.push(runCapture("golangci-lint", ["run"], repoRoot));
    results.push(runCapture("go", ["test", "./..."], repoRoot));
  }

  // Rust
  if (existsSync(join(repoRoot, "Cargo.toml"))) {
    results.push(runCapture("cargo", ["fmt", "--", "--check"], repoRoot));
    results.push(runCapture("cargo", ["clippy", "--", "-D", "warnings"], repoRoot));
    results.push(runCapture("cargo", ["test", "--quiet"], repoRoot));
  }

  // Shell scripts
  try {
    const shFiles = readdirSync(repoRoot).filter(f => f.endsWith('.sh'));
    if (shFiles.length > 0) {
      for (const f of shFiles) {
        results.push(runCapture("shellcheck", ["-x", f], repoRoot));
      }
    }
  } catch (e) {}

  // Summarize
  const summary = results.reduce(
    (acc, r) => {
      acc.errors += r.errors;
      acc.warnings += r.warnings;
      if (!r.ok) acc.failures += 1;
      return acc;
    },
    { errors: 0, warnings: 0, failures: 0 }
  );

  return { detected, results, summary };
}

function printTextReport(out: ReturnType<typeof runChecks>) {
  console.log("Detected tools:", out.detected.join(", "));
  for (const r of out.results) {
    console.log("---");
    console.log(`Tool: ${r.tool}`);
    console.log(`Exit: ${r.exitCode} | ok: ${r.ok} | errors: ${r.errors} | warnings: ${r.warnings}`);
    if (r.stdout) console.log(r.stdout.slice(0, 1000));
    if (r.stderr) console.error(r.stderr.slice(0, 1000));
  }
  console.log("---");
  console.log(`Summary: errors=${out.summary.errors} warnings=${out.summary.warnings} failing_tools=${out.summary.failures}`);
}

function main() {
  const argv = process.argv.slice(2);
  const opts: { path: string; format: string; fix: boolean; ci: boolean } = { path: process.cwd(), format: "text", fix: false, ci: false };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--path" && argv[i + 1]) { opts.path = argv[++i]; }
    else if (a === "--format" && argv[i + 1]) { opts.format = argv[++i]; }
    else if (a === "--fix") { opts.fix = true; }
    else if (a === "--ci") { opts.ci = true; }
    else if (a === "-h" || a === "--help") {
      console.log(`usage: code-lint [--path <dir>] [--format json|text] [--fix] [--ci]`);
      process.exit(0);
    }
  }

  const out = runChecks(opts.path, { fix: opts.fix, format: opts.format, ci: opts.ci });
  if (opts.format === "json") {
    // canonicalize results for JSON
    const canonical = {
      project_root: opts.path,
      detected: out.detected,
      summary: out.summary,
      results: out.results.map(r => ({ tool: r.tool, ok: r.ok, exitCode: r.exitCode, errors: r.errors, warnings: r.warnings, stdout: r.stdout, stderr: r.stderr })),
    };
    console.log(JSON.stringify(canonical, null, 2));
  } else {
    printTextReport(out);
  }

  if (opts.ci && out.summary.failures > 0) {
    process.exit(2);
  }
  // if any errors detected, exit non-zero when --ci provided only
}

main();
