# Contributing

## Scope

This repository stores Codex skills and their documentation.

## Workflow

1. Create a branch for your change.
2. Update or add skill files under `skills/<skill-name>/`.
3. Update docs in `docs/` when behavior or policy changes.
4. Follow `docs/authoring/quality-checklist.md` before opening a PR.

## Required in Each Skill

- `SKILL.md` with frontmatter `name` and `description`
- `agents/openai.yaml`
- Optional `scripts/`, `references/`, `assets/`

## Review Expectations

- Keep instructions deterministic when workflow is fragile.
- Keep SKILL body concise; push deep material into `references/`.
- Include runnable examples when scripts are provided.
