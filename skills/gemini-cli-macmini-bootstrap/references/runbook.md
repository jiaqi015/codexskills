# Gemini CLI Macmini Runbook

## One-Command Setup

```bash
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh --auth auto
```

## Verify Success

```bash
command -v gemini
gemini --version
gemini -p "Reply exactly OK" --output-format json
```

## Safe Audit Before Real Run

```bash
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh \
  --auth auto \
  --dry-run \
  --json-report -
```

## Common Failures and Fixes

### Auto mode fails in non-interactive shell

Message: `Auto mode in non-interactive shell requires API key`.

Fix:

```bash
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh --auth api-key --api-key "<KEY>"
```

### `gemini: command not found`

1. Check npm global prefix:

```bash
npm config get prefix
```

2. Add `<prefix>/bin` to PATH.
3. Open a new shell and run `gemini --version`.

### `Node.js < 20`

Bootstrap script auto-installs Node.js LTS using nvm.

### `ENOTFOUND registry.npmjs.org`

Network/DNS/proxy issue. Restore connectivity and rerun.

### Warning: both `GOOGLE_API_KEY` and `GEMINI_API_KEY` are set

Normalize to one key with:

```bash
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh --auth api-key --api-key "<KEY>" --persist-zshrc
```

### Need CI-friendly output

Use:

```bash
bash ~/.codex/skills/gemini-cli-macmini-bootstrap/scripts/bootstrap-gemini-cli.sh \
  --auth api-key --api-key "<KEY>" --no-smoke \
  --json-report /tmp/gemini-bootstrap-report.json
```
