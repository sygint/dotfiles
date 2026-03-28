#!/usr/bin/env bun
/*
 A_CODE_LINT: wrapper action that invokes the repository's code-lint helper
 and normalizes its output into a canonical JSON shape suitable for CI
 and Algorithm consumption.

 Usage examples:
  - bun .claude/PAI/ACTIONS/A_CODE_LINT.ts --path . --format json --ci
  - bun .claude/PAI/ACTIONS/A_CODE_LINT.ts --path ./packages/foo --fix
*/

import { spawnSync } from 'child_process'

function nowIso() { return new Date().toISOString() }

function parseArgs() {
  const args = process.argv.slice(2)
  const out: any = { flags: {}, passthrough: [] }
  for (let i = 0; i < args.length; i++) {
    const a = args[i]
    if (a === '--path' && args[i+1]) { out.flags.path = args[++i]; continue }
    if (a === '--format' && args[i+1]) { out.flags.format = args[++i]; continue }
    if (a === '--fix') { out.flags.fix = true; continue }
    if (a === '--ci') { out.flags.ci = true; continue }
    out.passthrough.push(a)
  }
  out.flags.path = out.flags.path || '.'
  out.flags.format = out.flags.format || 'text'
  return out
}

function findRunner() {
  try { spawnSync('bun', ['-v']) ; return { cmd: 'bun', run: (args: string[]) => spawnSync('bun', args, { encoding: 'utf8' }) } }
  catch (e) {}
  try { spawnSync('node', ['-v']) ; return { cmd: 'node', run: (args: string[]) => spawnSync('node', args, { encoding: 'utf8' }) } }
  catch (e) {}
  return null
}

async function main() {
  const parsed = parseArgs()
  // Enforce CI semantics: if --ci requested, force JSON output
  if (parsed.flags.ci) parsed.flags.format = 'json'

  const runner = findRunner()
  if (!runner) {
    console.error('A_CODE_LINT error: neither bun nor node found in PATH')
    process.exit(2)
  }

  const helperPath = '.claude/PAI/Tools/code-lint.ts'
  const helperArgs = [helperPath, '--path', parsed.flags.path, '--format', parsed.flags.format]
  if (parsed.flags.fix) helperArgs.push('--fix')
  if (parsed.flags.ci) helperArgs.push('--ci')
  helperArgs.push(...parsed.passthrough)

  const started = Date.now()
  const res = runner.run(helperArgs)
  const duration = Date.now() - started

  const stdout = res.stdout ?? ''
  const stderr = res.stderr ?? ''
  const exitCode = res.status == null ? (res.error ? 2 : 0) : res.status

  let raw: any = { stdout, stderr }
  let summary = { errors: 0, warnings: 0, fixable: 0, duration_ms: duration }
  // If helper returned JSON, parse and reuse its shape when possible
  if (parsed.flags.format === 'json') {
    try {
      const parsedJson = JSON.parse(stdout)
      raw.parsed = parsedJson
      if (parsedJson && typeof parsedJson === 'object') {
        if (parsedJson.summary && typeof parsedJson.summary === 'object') {
          summary.errors = parsedJson.summary.errors || 0
          summary.warnings = parsedJson.summary.warnings || 0
          summary.fixable = parsedJson.summary.fixable || 0
        }
      }
    } catch (e) {
      // fallthrough - keep raw stdout
      raw.parse_error = String(e)
    }
  }

  const out = {
    action: 'A_CODE_LINT',
    invocation: {
      path: parsed.flags.path,
      flags: parsed.flags,
      timestamp: nowIso(),
      runner: runner.cmd,
    },
    summary,
    tools: [
      {
        name: 'code-lint',
        cmd: `${runner.cmd} ${helperPath} ${helperArgs.map(a=>String(a)).join(' ')}`,
        exitCode,
        stdout: parsed.flags.format === 'json' ? undefined : stdout,
        stderr,
        duration_ms: duration,
      }
    ],
    raw,
  }

  // Print canonical JSON for consumers
  const printed = JSON.stringify(out, null, 2)
  if (parsed.flags.format === 'json') {
    console.log(printed)
  } else {
    // human-friendly: show helper stdout then a small wrapper summary
    process.stdout.write(stdout)
    console.log('\n---')
    console.log(printed)
  }

  // CI semantics: if --ci and errors > 0, exit non-zero to fail the job
  if (parsed.flags.ci && out.summary && out.summary.errors > 0) {
    process.exit(3)
  }

  // otherwise, mirror helper exit code (0 success)
  process.exit(exitCode ?? 0)
}

main().catch(err => {
  console.error('A_CODE_LINT unexpected error:', err)
  process.exit(2)
})
