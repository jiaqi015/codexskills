# Install Skills by Link

## Goal

Allow others to install a specific skill from this repository using one command.

## One Skill Install

```bash
curl -fsSL https://raw.githubusercontent.com/<owner>/<repo>/<ref>/scripts/install-skill-from-github.sh \
  | bash -s -- <owner>/<repo> <skill-folder> <ref> <workspace>
```

Example:

```bash
curl -fsSL https://raw.githubusercontent.com/jiaqi015/codexskills/main/scripts/install-skill-from-github.sh \
  | bash -s -- jiaqi015/codexskills gemini-cli-macmini-bootstrap main ~/.openclaw/workspace
```

Installed location:

- `<workspace>/skills/<skill-folder>`

## Browse Available Skills

Use `skills/INDEX.md` for the catalog and install commands.

Regenerate catalog after skill changes:

```bash
scripts/generate-skills-index.sh jiaqi015/codexskills main
```
