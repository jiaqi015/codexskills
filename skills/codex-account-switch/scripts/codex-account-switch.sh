#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  codex-account-switch.sh <action> [backend args...]

Actions:
  query | status | list | explain-order | reconcile
  add | schedule | set-default | promote | delete

Examples:
  codex-account-switch.sh status --agent main
  codex-account-switch.sh add --agent main --alias team-a
  codex-account-switch.sh schedule --agent main --primary team-a --fallback team-b --mode fixed

Backend resolution order:
  1) CODEX_AUTH_BACKEND_CMD
  2) codex-auth-manager.sh (PATH)
  3) $CODEX_HOME/skills/codex-reauth/scripts/codex-auth-manager.sh
USAGE
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" || "${1:-}" == "help" || "${#}" -eq 0 ]]; then
  usage
  exit 0
fi

action="$1"
shift || true

case "$action" in
  query|status|list|explain-order|reconcile|add|schedule|set-default|promote|delete) ;;
  *)
    echo "Unsupported action: $action" >&2
    usage >&2
    exit 2
    ;;
esac

resolve_backend() {
  if [[ -n "${CODEX_AUTH_BACKEND_CMD:-}" ]]; then
    printf '%s' "${CODEX_AUTH_BACKEND_CMD}"
    return 0
  fi

  if command -v codex-auth-manager.sh >/dev/null 2>&1; then
    printf '%s' "codex-auth-manager.sh"
    return 0
  fi

  local codex_home_default
  codex_home_default="${CODEX_HOME:-$HOME/.codex}"
  local fallback
  fallback="${codex_home_default}/skills/codex-reauth/scripts/codex-auth-manager.sh"

  if [[ -x "$fallback" ]]; then
    printf '%s' "$fallback"
    return 0
  fi

  return 1
}

backend="$(resolve_backend || true)"
if [[ -z "$backend" ]]; then
  cat >&2 <<'ERR'
No backend auth manager found.
Set CODEX_AUTH_BACKEND_CMD, or install a backend that provides codex-auth-manager.sh.
ERR
  exit 3
fi

# Keep entrypoint stable while delegating logic to backend.
exec "$backend" "$action" "$@"
