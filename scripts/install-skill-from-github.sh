#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Install one skill from a GitHub repository into OpenClaw workspace skills.

Usage:
  install-skill-from-github.sh <owner/repo> <skill-folder> [ref] [workspace]

Arguments:
  owner/repo    GitHub repository slug, e.g. jiaqi015/codexskills
  skill-folder  Folder under skills/, e.g. gemini-cli-macmini-bootstrap
  ref           Git ref (default: main)
  workspace     Target workspace root (default: current directory)

Result:
  Skill is installed to <workspace>/skills/<skill-folder>

Example:
  install-skill-from-github.sh jiaqi015/codexskills gemini-cli-macmini-bootstrap main ~/.openclaw/workspace
USAGE
}

log() {
  printf '[skill-install] %s\n' "$*"
}

die() {
  printf '[skill-install][error] %s\n' "$*" >&2
  exit 1
}

command -v curl >/dev/null 2>&1 || die "curl is required"
command -v tar >/dev/null 2>&1 || die "tar is required"

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi

[ $# -ge 2 ] || { usage; exit 1; }

REPO_SLUG="$1"
SKILL_FOLDER="$2"
REF="${3:-main}"
WORKSPACE="${4:-$PWD}"

case "$REPO_SLUG" in
  */*) ;;
  *) die "repo must be in owner/repo format" ;;
esac

case "$SKILL_FOLDER" in
  *[!a-zA-Z0-9._-]*) die "skill folder contains unsupported characters" ;;
  "") die "skill folder cannot be empty" ;;
esac

TARGET_ROOT="${WORKSPACE%/}/skills"
TARGET_DIR="${TARGET_ROOT}/${SKILL_FOLDER}"
TARBALL_URL="https://codeload.github.com/${REPO_SLUG}/tar.gz/${REF}"

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

ARCHIVE="$TMP_DIR/repo.tar.gz"

log "Downloading ${REPO_SLUG}@${REF}"
curl -fsSL "$TARBALL_URL" -o "$ARCHIVE" || die "failed to download repository archive"

ROOT_PREFIX="$(tar -tzf "$ARCHIVE" | head -n 1 | cut -d/ -f1)"
[ -n "$ROOT_PREFIX" ] || die "unable to inspect archive"

SKILL_PATH_IN_ARCHIVE="${ROOT_PREFIX}/skills/${SKILL_FOLDER}"
SKILL_MD_PATH_IN_ARCHIVE="${SKILL_PATH_IN_ARCHIVE}/SKILL.md"

tar -tzf "$ARCHIVE" "$SKILL_MD_PATH_IN_ARCHIVE" >/dev/null 2>&1 || \
  die "skill '${SKILL_FOLDER}' not found in ${REPO_SLUG}@${REF}"

mkdir -p "$TMP_DIR/extract"
tar -xzf "$ARCHIVE" -C "$TMP_DIR/extract" "$SKILL_PATH_IN_ARCHIVE"

SRC_DIR="$TMP_DIR/extract/$SKILL_PATH_IN_ARCHIVE"
[ -f "$SRC_DIR/SKILL.md" ] || die "extracted skill is invalid (missing SKILL.md)"

mkdir -p "$TARGET_ROOT"
if [ -d "$TARGET_DIR" ]; then
  BACKUP_DIR="${TARGET_DIR}.bak.$(date +%Y%m%d%H%M%S)"
  mv "$TARGET_DIR" "$BACKUP_DIR"
  log "Existing skill moved to backup: $BACKUP_DIR"
fi

cp -R "$SRC_DIR" "$TARGET_DIR"

log "Installed: $TARGET_DIR"
log "Run 'openclaw skills list' in your workspace to verify loading"
