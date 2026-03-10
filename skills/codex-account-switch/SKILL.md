---
name: codex-account-switch
description: Generic Codex auth switching and reauthorization workflow for OpenClaw. Use when users ask to switch Codex accounts, rotate subaccounts, reauth after org/account change, inspect auth order, or safely delete auth profiles.
metadata:
  short-description: Switch and manage Codex auth profiles safely
---

# Codex Account Switch

Use this skill to manage `openai-codex` account auth in a reusable, non-personalized way.

## Trigger Phrases

- `codex账号切换`
- `切换codex授权`
- `重授权codex`
- `codex多账号切换`
- `codex子账号轮换`
- `codex auth switch`
- `codex reauth`

## Entry Point

- Script: `skills/codex-account-switch/scripts/codex-account-switch.sh`

The script provides a stable interface. The actual backend implementation is injected via:

- `CODEX_AUTH_BACKEND_CMD` (recommended)
- fallback: `codex-auth-manager.sh` on `PATH`
- fallback: `$CODEX_HOME/skills/codex-reauth/scripts/codex-auth-manager.sh`

## Required Inputs

- `agent`: target agent id (default: `main`)
- `alias`: human-readable auth alias (for add/set-default/delete/promote)
- `fallback`: fallback alias list for scheduling when needed

## Workflow (Decoupled)

1. Inspect current state

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh status --agent main
skills/codex-account-switch/scripts/codex-account-switch.sh query --agent main
skills/codex-account-switch/scripts/codex-account-switch.sh explain-order --agent main
```

2. Add or refresh auth profile

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh add --agent main --alias team-a
```

Optional:

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh add --agent main --alias team-a --id team-a-1 --set-default
```

3. Switch scheduling chain

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh schedule --agent main --primary team-a --fallback team-b,team-c --mode smart
```

Modes:

- `fixed`: strict primary -> fallback order
- `random`: random order
- `smart`: health/risk-based order (if backend supports)

4. Set default / protected alias

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh set-default --agent main --alias team-a
skills/codex-account-switch/scripts/codex-account-switch.sh promote --agent main --alias team-a --set-default
```

5. Safe deletion

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh delete --agent main --alias team-c --yes
```

For protected aliases, require explicit human confirmation text:

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh delete --agent main --alias team-a --yes --super-confirm "DELETE PROTECTED team-a"
```

6. Reconcile snapshots with runtime source-of-truth

```bash
skills/codex-account-switch/scripts/codex-account-switch.sh reconcile --agent main
```

## Operational Rules

- Treat runtime auth profile store as source-of-truth.
- Treat policy/alias snapshot files as derived state.
- Never hardcode personal aliases, account names, host paths, or callback URLs.
- For destructive operations (`delete`, `promote`), always echo a confirmation summary before execution.

## Response Contract

When this skill runs in an agent turn:

1. First reply with a short ack and planned action.
2. Run exactly one operation at a time.
3. Return a concise result with:

- action
- agent
- target alias (if any)
- effective order/default (if changed)
- next safe command
