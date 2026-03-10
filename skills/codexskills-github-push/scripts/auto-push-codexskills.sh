#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/tmp/codexskills"
SET_ORIGIN=""
COMMIT_ALL=0
COMMIT_MESSAGE=""
DRY_RUN=0
KEY_PATH="${KEY_PATH:-$HOME/.ssh/codexskills_github_ed25519}"
AUTO_KEY=0
SKIP_PREPARE=0

usage() {
  cat <<'USAGE'
One-command flow: prepare GitHub SSH key, then push codexskills repo.

Usage:
  auto-push-codexskills.sh [options]

Options:
  --repo-dir <path>       Repository path (default: /tmp/codexskills)
  --set-origin <o/r>      Set origin to git@github.com:<owner>/<repo>.git
  --auto-key              Auto-select a working SSH key for target repo
  --skip-prepare          Skip key generation/check step
  --commit-all            Commit all changes before push
  --message <text>        Commit message (required with --commit-all)
  --dry-run               Validate and print push command without executing push
  -h, --help              Show help
USAGE
}

die() {
  printf '[auto-push][error] %s\n' "$*" >&2
  exit 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-dir)
      [ "$#" -ge 2 ] || die "--repo-dir requires a value"
      REPO_DIR="$2"
      shift 2
      ;;
    --set-origin)
      [ "$#" -ge 2 ] || die "--set-origin requires a value"
      SET_ORIGIN="$2"
      shift 2
      ;;
    --auto-key)
      AUTO_KEY=1
      shift
      ;;
    --skip-prepare)
      SKIP_PREPARE=1
      shift
      ;;
    --commit-all)
      COMMIT_ALL=1
      shift
      ;;
    --message)
      [ "$#" -ge 2 ] || die "--message requires a value"
      COMMIT_MESSAGE="$2"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown option: $1"
      ;;
  esac
done

BASE_DIR="$HOME/.codex/skills/codexskills-github-push/scripts"
PREP_SCRIPT="$BASE_DIR/prepare-github-key.sh"
PUSH_SCRIPT="$BASE_DIR/push-repo-with-key.sh"

[ -x "$PREP_SCRIPT" ] || die "missing script: $PREP_SCRIPT"
[ -x "$PUSH_SCRIPT" ] || die "missing script: $PUSH_SCRIPT"

if [ "$SKIP_PREPARE" -ne 1 ]; then
  "$PREP_SCRIPT" --key-path "$KEY_PATH" >/dev/null
fi

args=(--repo-dir "$REPO_DIR" --key-path "$KEY_PATH")

if [ -n "$SET_ORIGIN" ]; then
  args+=(--set-origin "$SET_ORIGIN")
fi
if [ "$COMMIT_ALL" -eq 1 ]; then
  [ -n "$COMMIT_MESSAGE" ] || die "--commit-all requires --message"
  args+=(--commit-all --message "$COMMIT_MESSAGE")
fi
if [ "$DRY_RUN" -eq 1 ]; then
  args+=(--dry-run)
fi
if [ "$AUTO_KEY" -eq 1 ]; then
  args+=(--auto-key)
fi

"$PUSH_SCRIPT" "${args[@]}"
