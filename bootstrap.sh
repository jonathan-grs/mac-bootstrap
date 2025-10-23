#!/usr/bin/env bash
set -euo pipefail
echo "[bootstrap] Installing Xcode CLT…"
xcode-select -p >/dev/null 2>&1 || xcode-select --install || true

echo "[bootstrap] Installing Homebrew…"
if ! command -v brew >/dev/null 2>&1; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
[ -d /opt/homebrew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
[ -d /usr/local/Homebrew ] && eval "$(/usr/local/bin/brew shellenv)"

echo "[bootstrap] Installing yadm & gh…"
brew install yadm gh || true

echo "[bootstrap] GitHub device login (no PAT/SSH yet)…"
gh auth status >/dev/null 2>&1 || gh auth login -p https -w

echo "[bootstrap] Cloning private dotfiles via HTTPS token & bootstrapping…"
# Use HTTPS; gh’s credential helper injects your token automatically
yadm clone --bootstrap https://github.com/jonathan-grs/dotfiles.git

echo "[bootstrap] Done."
