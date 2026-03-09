# Quick Start

## 1. Clone and Inspect

```bash
git clone git@github.com:jiaqi015/codexskills.git
cd codexskills
```

## 2. Create Your First Skill

```bash
mkdir -p skills/my-skill/agents
cat > skills/my-skill/SKILL.md <<'MD'
---
name: my-skill
description: Example skill description with explicit trigger conditions.
---

# My Skill

Add concise instructions here.
MD
```

## 3. Add Agent Metadata

Create `skills/my-skill/agents/openai.yaml` with display metadata.

## 4. Validate Against Checklist

Use: `docs/authoring/quality-checklist.md`

## 5. Open PR

Follow: `docs/authoring/review-and-release.md`
