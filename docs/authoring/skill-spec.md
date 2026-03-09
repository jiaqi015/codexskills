# Skill Authoring Spec

## Frontmatter Rules

`SKILL.md` frontmatter must include:

- `name`
- `description`

Description must state what the skill does and when it should trigger.

## Writing Rules

- Use imperative instructions.
- Keep steps explicit for fragile workflows.
- Put long references into `references/`.
- Use scripts for deterministic/repeated operations.

## Trigger Quality

A good description includes:

1. task type
2. trigger contexts
3. file/system scope when relevant

## Resource Design

- `scripts/`: executable, tested utilities
- `references/`: deep docs loaded on demand
- `assets/`: output templates and static resources
