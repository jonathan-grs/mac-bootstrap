#!/usr/bin/env bash
set -euo pipefail

EXPECTED_REMOTE="https://github.com/<YOU>/<PRIVATE_DOTFILES>.git"

log() { printf "\e[1;36m[bootstrap]\e[0m %s\n" "$*"; }

ensure_xcode() {
  if ! xcode-select -p >/dev/null 2>&1; then
    log "Installing Xcode Command Line Tools…"
    xcode-select --install || true
  fi
}

ensure_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Installing Homebrew…"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  if [[ -x /opt/homebrew/bin/brew ]]; then eval "$(/opt/homebrew/bin/brew shellenv)"; fi
  if [[ -x /usr/local/bin/brew   ]]; then eval "$(/usr/local/bin/brew shellenv)"; fi
}

ensure_tools() {
  log "Installing yadm, gh, and mas (if missing)…"
  brew install yadm gh mas >/dev/null || true
  if ! gh auth status >/dev/null 2>&1; then
    log "GitHub device login (browser will open)…"
    gh auth login -p https -w
  fi
}

clone_or_update_yadm_repo() {
  if yadm rev-parse --git-dir >/dev/null 2>&1; then
    log "yadm repo exists; pulling latest…"
    yadm pull --rebase --autostash || yadm pull || true
  else
    log "Cloning dotfiles (no bootstrap yet)…"
    yadm clone "$EXPECTED_REMOTE"
  fi
}

wait_for_mas_login() {
  # mas is now guaranteed to be installed
  if mas account >/dev/null 2>&1; then
    log "App Store already signed in ✅"
    return
  fi
  log "Opening App Store — please sign in (2FA if needed)…"
  open -a "App Store" || true
  until mas account >/dev/null 2>&1; do
    sleep 5
  done
  log "App Store sign-in detected ✅"
}

run_yadm_bootstrap() {
  log "Running yadm bootstrap (this may take a while)…"
  yadm bootstrap
  log "All done 🎉"
}

main() {
  ensure_xcode
  ensure_homebrew
  ensure_tools      # <— installs mas
  clone_or_update_yadm_repo
  wait_for_mas_login
  run_yadm_bootstrap
}

main "$@"