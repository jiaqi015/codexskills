# Quality Checklist

Use this checklist before creating a PR.

## Required

- [ ] Skill name is lowercase-hyphen-case
- [ ] `SKILL.md` has valid frontmatter (`name`, `description`)
- [ ] `description` includes explicit trigger conditions
- [ ] `agents/openai.yaml` exists

## Content Quality

- [ ] Instructions are unambiguous
- [ ] Risky operations have guardrails
- [ ] No redundant long explanations in `SKILL.md`
- [ ] Deep material moved to `references/`

## Script Quality (if scripts exist)

- [ ] Script is executable
- [ ] Script was run at least once
- [ ] Failure messages are actionable

## Maintainability

- [ ] Documentation index updated (`docs/README.md`)
- [ ] Examples are current
- [ ] Ownership path is clear
