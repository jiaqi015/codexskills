#!/usr/bin/env bash
set -euo pipefail

AUTH_MODE="auto"
API_KEY=""
PERSIST_ZSHRC=0
RUN_SMOKE=1
UPGRADE_IF_PRESENT=0
MODEL="gemini-2.5-flash-lite"
PROMPT="Reply exactly OK"
NVM_VERSION_TAG="v0.40.3"

log() {
  printf '[gemini-bootstrap] %s\n' "$*"
}

warn() {
  printf '[gemini-bootstrap][warn] %s\n' "$*" >&2
}

die() {
  printf '[gemini-bootstrap][error] %s\n' "$*" >&2
  exit 1
}

is_interactive_terminal() {
  [ -t 0 ] && [ -t 1 ]
}

usage() {
  cat <<'USAGE'
Usage:
  bootstrap-gemini-cli.sh [options]

Options:
  --auth <auto|oauth|api-key>  Authentication mode (default: auto)
  --api-key <key>              API key used for --auth api-key
  --persist-zshrc              Persist GEMINI_API_KEY to ~/.zshrc and remove GOOGLE_API_KEY export
  --upgrade                    Upgrade @google/gemini-cli when already installed
  --no-smoke                   Skip final smoke test
  --model <model>              Model used in smoke test (default: gemini-2.5-flash-lite)
  --prompt <text>              Prompt used in smoke test (default: "Reply exactly OK")
  -h, --help                   Show this help

Examples:
  bootstrap-gemini-cli.sh --auth auto
  bootstrap-gemini-cli.sh --auth oauth
  bootstrap-gemini-cli.sh --auth api-key --api-key "$GEMINI_API_KEY" --persist-zshrc
  bootstrap-gemini-cli.sh --auth auto --upgrade
USAGE
}

escape_single_quotes() {
  printf "%s" "$1" | sed "s/'/'\"'\"'/g"
}

remove_conflicting_key_exports() {
  local zshrc="$HOME/.zshrc"
  local tmp

  mkdir -p "$(dirname "$zshrc")"
  touch "$zshrc"
  tmp="$(mktemp)"

  awk '!/^export GEMINI_API_KEY=/ && !/^export GOOGLE_API_KEY=/' "$zshrc" >"$tmp"
  mv "$tmp" "$zshrc"
}

persist_gemini_key() {
  local key="$1"
  local zshrc="$HOME/.zshrc"
  local escaped

  remove_conflicting_key_exports
  escaped="$(escape_single_quotes "$key")"

  {
    printf '\n# Added by gemini-cli-macmini-bootstrap\n'
    printf "export GEMINI_API_KEY='%s'\n" "$escaped"
  } >>"$zshrc"

  log "Persisted GEMINI_API_KEY to ~/.zshrc"
}

node_major() {
  if ! command -v node >/dev/null 2>&1; then
    echo 0
    return
  fi
  node -p "Number(process.versions.node.split('.')[0])" 2>/dev/null || echo 0
}

ensure_nvm_loaded() {
  export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

  if [ -s "$NVM_DIR/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
    return
  fi

  command -v curl >/dev/null 2>&1 || die "curl is required to install nvm"

  log "Installing nvm ($NVM_VERSION_TAG)"
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION_TAG}/install.sh" | bash

  [ -s "$NVM_DIR/nvm.sh" ] || die "nvm install failed"
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
}

ensure_node() {
  local major
  major="$(node_major)"

  if [ "$major" -ge 20 ]; then
    log "Node.js already available: $(node -v)"
    return
  fi

  ensure_nvm_loaded
  log "Installing Node.js LTS via nvm"
  nvm install --lts
  nvm alias default 'lts/*' >/dev/null
  nvm use default >/dev/null

  major="$(node_major)"
  [ "$major" -ge 20 ] || die "Node.js >=20 is required after installation"
  log "Node.js ready: $(node -v)"
}

check_npm_registry() {
  command -v curl >/dev/null 2>&1 || die "curl is required for npm registry preflight"
  curl -fsS --connect-timeout 8 https://registry.npmjs.org/@google%2fgemini-cli >/dev/null || \
    die "Cannot reach npm registry. Check DNS/proxy/network and retry."
}

ensure_gemini_on_path() {
  if command -v gemini >/dev/null 2>&1; then
    return
  fi

  local npm_bin
  npm_bin="$(npm config get prefix)/bin"
  export PATH="$npm_bin:$PATH"

  command -v gemini >/dev/null 2>&1 || die "gemini not found in PATH after installation"
  warn "Temporarily added $npm_bin to PATH for this session"
}

ensure_gemini_cli() {
  if command -v gemini >/dev/null 2>&1 && [ "$UPGRADE_IF_PRESENT" -ne 1 ]; then
    log "Gemini CLI already installed: $(gemini --version)"
    return
  fi

  command -v npm >/dev/null 2>&1 || die "npm is required"
  check_npm_registry

  if command -v gemini >/dev/null 2>&1; then
    log "Upgrading @google/gemini-cli"
  else
    log "Installing @google/gemini-cli"
  fi

  npm install -g @google/gemini-cli@latest >/dev/null
  ensure_gemini_on_path
  log "Gemini CLI version: $(gemini --version)"
}

normalize_auth_mode() {
  case "$AUTH_MODE" in
    auto|oauth|api-key) ;;
    *) die "Invalid --auth value: $AUTH_MODE" ;;
  esac

  if [ "$AUTH_MODE" = "auto" ]; then
    if [ -n "$API_KEY" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then
      AUTH_MODE="api-key"
    elif is_interactive_terminal; then
      AUTH_MODE="oauth"
    else
      die "Auto mode in non-interactive shell requires API key. Use --auth api-key --api-key '<KEY>'."
    fi
  fi

  if [ "$AUTH_MODE" = "oauth" ] && ! is_interactive_terminal; then
    die "OAuth mode requires an interactive terminal."
  fi

  log "Auth mode: $AUTH_MODE"
}

prompt_api_key_if_needed() {
  if [ "$AUTH_MODE" != "api-key" ]; then
    return
  fi

  if [ -n "$API_KEY" ] || [ -n "${GEMINI_API_KEY:-}" ] || [ -n "${GOOGLE_API_KEY:-}" ]; then
    return
  fi

  if ! is_interactive_terminal; then
    die "API key mode requires --api-key (non-interactive shell)."
  fi

  printf 'Paste Gemini API key (input hidden): ' >&2
  read -r -s API_KEY
  printf '\n' >&2

  [ -n "$API_KEY" ] || die "Empty API key input"
}

setup_api_key_auth() {
  if [ -n "$API_KEY" ]; then
    export GEMINI_API_KEY="$API_KEY"
  elif [ -z "${GEMINI_API_KEY:-}" ] && [ -n "${GOOGLE_API_KEY:-}" ]; then
    export GEMINI_API_KEY="$GOOGLE_API_KEY"
  fi

  [ -n "${GEMINI_API_KEY:-}" ] || die "API key mode requires GEMINI_API_KEY"

  if [ -n "${GOOGLE_API_KEY:-}" ]; then
    warn "GOOGLE_API_KEY is set. Unsetting it for this session to avoid dual-key warning."
    unset GOOGLE_API_KEY
  fi

  if [ "$PERSIST_ZSHRC" -eq 1 ]; then
    persist_gemini_key "$GEMINI_API_KEY"
  fi
}

run_oauth_auth() {
  log "Launching interactive Gemini login. Complete browser auth, then exit Gemini with Ctrl+C or /quit."
  gemini
}

run_smoke_test() {
  local out

  if [ "$RUN_SMOKE" -ne 1 ]; then
    log "Smoke test skipped"
    return
  fi

  log "Running smoke test"
  set +e
  out="$(gemini -m "$MODEL" -p "$PROMPT" --output-format json 2>&1)"
  local status=$?
  set -e

  printf '%s\n' "$out"

  [ $status -eq 0 ] || die "Smoke test command failed"
  printf '%s' "$out" | grep -q '"response"' || die "Smoke test output missing JSON response"

  log "Smoke test passed"
}

parse_args() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --auth)
        [ "$#" -ge 2 ] || die "--auth requires a value"
        AUTH_MODE="$2"
        shift 2
        ;;
      --api-key)
        [ "$#" -ge 2 ] || die "--api-key requires a value"
        API_KEY="$2"
        shift 2
        ;;
      --persist-zshrc)
        PERSIST_ZSHRC=1
        shift
        ;;
      --upgrade)
        UPGRADE_IF_PRESENT=1
        shift
        ;;
      --no-smoke)
        RUN_SMOKE=0
        shift
        ;;
      --model)
        [ "$#" -ge 2 ] || die "--model requires a value"
        MODEL="$2"
        shift 2
        ;;
      --prompt)
        [ "$#" -ge 2 ] || die "--prompt requires a value"
        PROMPT="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        die "Unknown option: $1"
        ;;
    esac
  done
}

main() {
  parse_args "$@"
  normalize_auth_mode
  prompt_api_key_if_needed
  ensure_node
  ensure_gemini_cli

  if [ "$AUTH_MODE" = "api-key" ]; then
    setup_api_key_auth
  else
    run_oauth_auth
  fi

  run_smoke_test

  log "Done. Gemini CLI is installed and authenticated."
}

main "$@"
