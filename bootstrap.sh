#!/usr/bin/env bash
set -euo pipefail

EXPECTED_REMOTE="https://github.com/jonathan_grs/dotfiles.git"

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
  
  # Check if we can access the App Store by attempting to search
  # (requires authentication). Use a known Apple app like Pages.
  if mas search "Pages" >/dev/null 2>&1; then
    log "App Store access verified ✅"
    return 0
  fi
  
  log "Opening App Store — please sign in (2FA if needed)…"
  open -a "App Store" || true
  
  # Poll until we can successfully search the store
  until mas search "Pages" >/dev/null 2>&1; do
    sleep 5
  done
  log "App Store sign-in detected ✅"
}

run_yadm_bootstrap() {
  log "Running yadm bootstrap (this may take a while)…"
  yadm bootstrap
  log "All done 🎉"
}

run_brew_bundle() {
  log "Installing software via Homebrew (this may take a while)…"
  brew bundle --file="$(git rev-parse --show-toplevel)/Brewfile" --cleanup
}

main() {
  ensure_xcode
  ensure_homebrew
  ensure_tools      # <— installs mas
  clone_or_update_yadm_repo
  wait_for_mas_login
  # run_yadm_bootstrap
  run_brew_bundle
}

main "$@"