# Repository Layout

## Proposed Top-Level Structure

- `skills/`: all skill packages
- `docs/`: shared process and standards
- `.github/`: CI and PR templates (optional but recommended)

## Skill Package Structure

Each skill should look like:

```text
skills/<skill-name>/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── scripts/        # optional
├── references/     # optional
└── assets/         # optional
```

## Naming Rules

- Skill folder: lowercase-hyphen-case
- One responsibility per skill
- Keep `SKILL.md` concise and focused
