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
  # Strategy: (1) prefer `mas account` when supported, (2) inspect common
  # App Store preference domains for account-like keys (works when mas or
  # its subcommands are unavailable), (3) interactive fallback: open App
  # Store and poll until sign-in is detected or user confirms.

  # 1) Try `mas account` if available
  if command -v mas >/dev/null 2>&1 && mas help 2>&1 | grep -qi "account"; then
    if mas account >/dev/null 2>&1; then
      log "App Store already signed in ✅"
      return
    fi
  fi

  # 2) Inspect common preference domains for the App Store / storeagent
  # which may contain account metadata on some macOS versions. This is a
  # best-effort check and may vary by OS version.
  for domain in com.apple.storeagent com.apple.storeaccount com.apple.appstore; do
    if defaults read "$domain" >/dev/null 2>&1; then
      if defaults read "$domain" 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -qE 'account|appleid|apple_id|dsid|userid'; then
        log "Detected App Store account in $domain ✅"
        return
      fi
    fi
  done

  # 3) Fallback: open App Store and poll for sign-in using the methods above.
  log "Opening App Store — please sign in (2FA if needed)…"
  open -a "App Store" || true
  while true; do
    # Re-check mas account if possible
    if command -v mas >/dev/null 2>&1 && mas help 2>&1 | grep -qi "account" && mas account >/dev/null 2>&1; then
      log "App Store sign-in detected via 'mas account' ✅"
      break
    fi
    # Re-check preference domains
    signed_in=false
    for domain in com.apple.storeagent com.apple.storeaccount com.apple.appstore; do
      if defaults read "$domain" >/dev/null 2>&1; then
        if defaults read "$domain" 2>/dev/null | tr '[:upper:]' '[:lower:]' | grep -qE 'account|appleid|apple_id|dsid|userid'; then
          log "Detected App Store account in $domain ✅"
          signed_in=true
          break
        fi
      fi
    done
    if [ "$signed_in" = true ]; then
      break
    fi
    # As a last resort, prompt the user to confirm they signed in and press Enter
    # (useful in CI-like interactive runs).
    echo
    log "If you've signed into the App Store, press Enter to continue; otherwise wait and App Store will be polled every 5s."
    # Read with timeout: wait 5 seconds for input, otherwise continue looping
    if read -t 5 -r _; then
      log "User confirmed sign-in — continuing ✅"
      break
    fi
  done
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