---
name: codexskills-github-push
description: Standard workflow for pushing a local Codex skills repository to GitHub using a dedicated SSH key. Use when the user wants to publish new skills, push updates to existing skills, or handle both new and modified files with deterministic checks (key generation, GitHub SSH auth validation, optional commit, and push).
---

# CodexSkills GitHub Push

## Overview

Use this skill to make `codexskills` push operations repeatable and low-risk.
Handle both cases: only updates, only new files, or mixed updates + additions.

## Quick Commands

```bash
# One-command auto flow: auto-pick working key + push
bash ~/.codex/skills/codexskills-github-push/scripts/auto-push-codexskills.sh \
  --repo-dir /tmp/codexskills \
  --set-origin <owner>/<repo> \
  --auto-key

# Auto flow with updates + additions commit
bash ~/.codex/skills/codexskills-github-push/scripts/auto-push-codexskills.sh \
  --repo-dir /tmp/codexskills \
  --commit-all \
  --message "chore: update and add skills"

# Manual split flow
bash ~/.codex/skills/codexskills-github-push/scripts/prepare-github-key.sh
bash ~/.codex/skills/codexskills-github-push/scripts/push-repo-with-key.sh --repo-dir /tmp/codexskills
```

## Workflow

1. Ensure SSH key exists (`prepare-github-key.sh`).
2. Add printed public key to GitHub -> Settings -> SSH and GPG keys.
3. Run `auto-push-codexskills.sh --auto-key` for one-command flow.
4. Confirm push output contains branch update on target remote.

## Guardrails

- Never print private key content.
- Do not force-push automatically.
- Commit step is opt-in (`--commit-all`) and requires explicit message.
- Prefer `--auto-key` to avoid key mismatch failures across repos/accounts.

## References

- Operational runbook: `references/runbook.md`
