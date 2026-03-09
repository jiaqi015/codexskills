---
name: gemini-cli-macmini-bootstrap
description: End-to-end bootstrap for Gemini CLI on a fresh macOS or Mac mini. Install Node.js (with nvm when needed), install or upgrade @google/gemini-cli, complete authentication with either Google OAuth or API key, and run smoke tests. Use when a user asks to set up Gemini CLI from zero, migrate to a new Mac, fix first-run auth issues, or provide a repeatable one-command onboarding flow with high success rate.
---

# Gemini CLI Macmini Bootstrap

## Overview

Run one script to finish install, auth, and verification for `gemini` on a new Mac mini.
Default behavior favors the simplest successful path for humans.

## Quick Start

```bash
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh --auth auto
```

Behavior of `--auth auto`:
- If API key exists, use API key mode.
- Else if terminal is interactive, use OAuth login.
- Else fail fast with a clear command requiring `--api-key`.

## Audit and CI Modes

```bash
# Dry-run: no side effects, prints plan
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh \
  --auth auto \
  --dry-run

# Emit machine-readable JSON summary to stdout
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh \
  --auth auto \
  --dry-run \
  --json-report -

# Emit JSON summary to file
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh \
  --auth api-key \
  --api-key "<YOUR_GEMINI_API_KEY>" \
  --no-smoke \
  --json-report /tmp/gemini-bootstrap-report.json
```

## High-Success Playbook

1. Prefer `--auth auto` for normal human setup.
2. Use `--auth api-key --api-key "<KEY>"` for automation/non-interactive shells.
3. Add `--persist-zshrc` to keep key across terminal restarts.
4. Add `--upgrade` only when you explicitly want latest CLI.
5. Add `--dry-run` before rollout when auditing run plans.

## Script Contract

The bootstrap script must:
- Ensure Node.js `>=20` exists (install LTS with `nvm` when needed).
- Install `@google/gemini-cli` when missing; skip reinstall unless `--upgrade`.
- Complete auth using selected mode.
- Run smoke test with JSON output unless `--no-smoke`.
- Support side-effect-free audit mode via `--dry-run`.
- Support machine-readable result output via `--json-report`.
- Exit non-zero on hard failures with actionable messages.

## Guardrails

- Do not print raw API keys in logs.
- Avoid keeping both `GEMINI_API_KEY` and `GOOGLE_API_KEY` in persistent shell config for the same Gemini API-key flow.
- Fail fast in non-interactive OAuth-incompatible scenarios.

## References

- Troubleshooting and recoveries: `references/runbook.md`
