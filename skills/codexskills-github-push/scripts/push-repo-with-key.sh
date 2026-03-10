#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$PWD"
KEY_PATH="${KEY_PATH:-$HOME/.ssh/codexskills_github_ed25519}"
TARGET_BRANCH=""
SET_ORIGIN_SLUG=""
COMMIT_ALL=0
COMMIT_MESSAGE=""
DRY_RUN=0
AUTO_KEY=0

usage() {
  cat <<'USAGE'
Push a git repository to GitHub using a dedicated SSH key.

Usage:
  push-repo-with-key.sh [options]

Options:
  --repo-dir <path>       Repository path (default: current directory)
  --key-path <path>       SSH private key path (default: ~/.ssh/codexskills_github_ed25519)
  --auto-key              Auto-select a working SSH key with repo write access
  --branch <name>         Push branch (default: current branch, fallback main)
  --set-origin <o/r>      Set origin to git@github.com:<owner>/<repo>.git before push
  --commit-all            Run git add -A and create a commit before push
  --message <text>        Commit message used with --commit-all
  --dry-run               Validate and print planned push command without executing
  -h, --help              Show help

Examples:
  push-repo-with-key.sh --repo-dir /tmp/codexskills
  push-repo-with-key.sh --repo-dir /tmp/codexskills --set-origin jiaqi015/codexskills
  push-repo-with-key.sh --repo-dir /tmp/codexskills --commit-all --message "chore: update skills"
USAGE
}

log() {
  printf '[push-with-key] %s\n' "$*"
}

die() {
  printf '[push-with-key][error] %s\n' "$*" >&2
  exit 1
}

origin_to_slug() {
  local origin_url="$1"
  case "$origin_url" in
    git@github.com:*.git)
      printf '%s' "${origin_url#git@github.com:}" | sed 's/\.git$//'
      ;;
    https://github.com/*/*.git|https://github.com/*/*)
      printf '%s' "${origin_url#https://github.com/}" | sed 's/\.git$//'
      ;;
    *)
      return 1
      ;;
  esac
}

collect_candidate_keys() {
  local -a keys=()
  if [ -n "${KEY_PATH:-}" ] && [ -f "$KEY_PATH" ]; then
    keys+=("$KEY_PATH")
  fi
  if [ -f "$HOME/.ssh/id_ed25519" ]; then
    keys+=("$HOME/.ssh/id_ed25519")
  fi
  if [ -f "$HOME/.ssh/id_rsa" ]; then
    keys+=("$HOME/.ssh/id_rsa")
  fi
  if [ -f "$HOME/.ssh/id_ed25519_yangjiaqi_ai" ]; then
    keys+=("$HOME/.ssh/id_ed25519_yangjiaqi_ai")
  fi
  while IFS= read -r f; do
    [ -f "$f" ] && keys+=("$f")
  done < <(find "$HOME/.ssh" -maxdepth 1 -type f \( -name '*github*ed25519' -o -name '*github*id_rsa' -o -name '*github*key*' \) 2>/dev/null | sort)
  printf '%s\n' "${keys[@]}" | awk 'NF && !seen[$0]++'
}

test_repo_access_with_key() {
  local key="$1"
  GIT_SSH_COMMAND="ssh -i $key -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" \
    git ls-remote --exit-code origin HEAD >/dev/null 2>&1
}

pick_working_key() {
  local key
  while IFS= read -r key; do
    [ -n "$key" ] || continue
    if test_repo_access_with_key "$key"; then
      printf '%s' "$key"
      return 0
    fi
  done < <(collect_candidate_keys)
  return 1
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --repo-dir)
      [ "$#" -ge 2 ] || die "--repo-dir requires a value"
      REPO_DIR="$2"
      shift 2
      ;;
    --key-path)
      [ "$#" -ge 2 ] || die "--key-path requires a value"
      KEY_PATH="$2"
      shift 2
      ;;
    --auto-key)
      AUTO_KEY=1
      shift
      ;;
    --branch)
      [ "$#" -ge 2 ] || die "--branch requires a value"
      TARGET_BRANCH="$2"
      shift 2
      ;;
    --set-origin)
      [ "$#" -ge 2 ] || die "--set-origin requires a value"
      SET_ORIGIN_SLUG="$2"
      shift 2
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

command -v git >/dev/null 2>&1 || die "git is required"
command -v ssh >/dev/null 2>&1 || die "ssh is required"

cd "$REPO_DIR"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 || die "not a git repo: $REPO_DIR"

if [ -n "$SET_ORIGIN_SLUG" ]; then
  case "$SET_ORIGIN_SLUG" in
    */*) ;;
    *) die "--set-origin must be owner/repo format" ;;
  esac
  origin_url="git@github.com:${SET_ORIGIN_SLUG}.git"
  if git remote get-url origin >/dev/null 2>&1; then
    git remote set-url origin "$origin_url"
    log "Updated origin -> $origin_url"
  else
    git remote add origin "$origin_url"
    log "Added origin -> $origin_url"
  fi
fi

origin_url="$(git remote get-url origin 2>/dev/null || true)"
[ -n "$origin_url" ] || die "origin remote is missing. Use --set-origin owner/repo"

# Convert GitHub HTTPS remote to SSH to avoid interactive username/password failures.
if printf '%s' "$origin_url" | grep -q '^https://github.com/'; then
  slug="$(origin_to_slug "$origin_url" || true)"
  [ -n "$slug" ] || die "unable to parse GitHub HTTPS origin: $origin_url"
  origin_url="git@github.com:${slug}.git"
  git remote set-url origin "$origin_url"
  log "Converted origin to SSH -> $origin_url"
fi

if [ -z "$TARGET_BRANCH" ]; then
  TARGET_BRANCH="$(git branch --show-current)"
  [ -n "$TARGET_BRANCH" ] || TARGET_BRANCH="main"
fi

if [ "$COMMIT_ALL" -eq 1 ]; then
  [ -n "$COMMIT_MESSAGE" ] || die "--commit-all requires --message"
  git add -A
  if git diff --cached --quiet; then
    log "No staged changes after git add -A; skip commit"
  else
    git commit -m "$COMMIT_MESSAGE"
    log "Committed changes"
  fi
fi

if [ "$AUTO_KEY" -eq 1 ]; then
  KEY_PATH="$(pick_working_key || true)"
  [ -n "$KEY_PATH" ] || die "no working SSH key found for origin; add deploy/user key and retry"
  log "Auto-selected SSH key: $KEY_PATH"
fi

[ -f "$KEY_PATH" ] || die "SSH key not found: $KEY_PATH (tip: use --auto-key)"

if ! test_repo_access_with_key "$KEY_PATH"; then
  err="$(GIT_SSH_COMMAND="ssh -i $KEY_PATH -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" git ls-remote --exit-code origin HEAD 2>&1 || true)"
  printf '%s\n' "$err" >&2
  die "SSH key cannot access origin. Check repo permissions/key binding or use --auto-key."
fi

push_cmd=(git push origin "$TARGET_BRANCH")

local_head="$(git rev-parse "$TARGET_BRANCH" 2>/dev/null || true)"
remote_head="$(GIT_SSH_COMMAND="ssh -i $KEY_PATH -o IdentitiesOnly=yes -o StrictHostKeyChecking=accept-new" git ls-remote origin "refs/heads/$TARGET_BRANCH" | awk 'NR==1{print $1}')"
if [ -n "$local_head" ] && [ -n "$remote_head" ] && [ "$local_head" = "$remote_head" ]; then
  log "No new commits to push on branch $TARGET_BRANCH; already up to date"
  exit 0
fi

if [ "$DRY_RUN" -eq 1 ]; then
  log "Dry run OK"
  log "Origin: $origin_url"
  log "Branch: $TARGET_BRANCH"
  log "Command: GIT_SSH_COMMAND='ssh -i $KEY_PATH -o IdentitiesOnly=yes' ${push_cmd[*]}"
  exit 0
fi

log "Pushing $TARGET_BRANCH -> $origin_url"
GIT_SSH_COMMAND="ssh -i $KEY_PATH -o IdentitiesOnly=yes" "${push_cmd[@]}"
log "Push completed"
