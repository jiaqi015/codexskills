# CodexSkills GitHub Push Runbook

## Scenario A: One-command auto push

```bash
bash ~/.codex/skills/codexskills-github-push/scripts/auto-push-codexskills.sh \
  --repo-dir /tmp/codexskills \
  --set-origin <owner>/<repo> \
  --auto-key
```

## Scenario B: First-time push with split steps

1. Generate key and copy public key:

```bash
bash ~/.codex/skills/codexskills-github-push/scripts/prepare-github-key.sh
```

2. Add public key to GitHub:
- GitHub -> Settings -> SSH and GPG keys -> New SSH key

3. Push repo with key:

```bash
bash ~/.codex/skills/codexskills-github-push/scripts/push-repo-with-key.sh \
  --repo-dir /tmp/codexskills \
  --set-origin <owner>/<repo> \
  --auto-key
```

## Scenario C: Repo has both updates and new files

```bash
bash ~/.codex/skills/codexskills-github-push/scripts/auto-push-codexskills.sh \
  --repo-dir /tmp/codexskills \
  --commit-all \
  --message "chore: update and add skills" \
  --auto-key
```

## Scenario D: Only verify without pushing

```bash
bash ~/.codex/skills/codexskills-github-push/scripts/auto-push-codexskills.sh \
  --repo-dir /tmp/codexskills \
  --dry-run \
  --auto-key
```

## Scenario E: Existing key already works, skip key prep for speed

```bash
bash ~/.codex/skills/codexskills-github-push/scripts/auto-push-codexskills.sh \
  --repo-dir /tmp/codexskills \
  --skip-prepare \
  --auto-key
```

## Troubleshooting

### Permission denied (publickey)

- Ensure the public key from `prepare-github-key.sh` was added to the correct GitHub account.
- Re-run dry-run to confirm authentication.

### `origin remote is missing`

Use:

```bash
--set-origin <owner/repo>
```

### No commit created with `--commit-all`

The script skips commit when there are no staged changes after `git add -A`.
