# mac-bootstrap 🚀

Bootstrap a fresh macOS installation with essential tools and dotfiles.

## Quick Start

Paste this command into a fresh macOS terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/jonathan-grs/mac-bootstrap/main/bootstrap.sh | /bin/bash
```

### What this does

1. Installs **Xcode Command Line Tools** (for `git` and compilers)
2. Installs **Homebrew** (package manager)
3. Installs **yadm** (dotfiles manager), **GitHub CLI (`gh`)**, and **mas** (Mac App Store CLI)
4. Opens a **GitHub device login** (secure, no PAT or SSH key required)
5. Clones your **private dotfiles repo** using HTTPS authentication
6. Waits for **App Store sign-in** (opens App Store if needed)
7. Installs software via Homebrew and Brewfile

## Notes

* The script is **idempotent** — you can safely run it again anytime
* You'll need to:
  - Complete GitHub device authentication when prompted (browser will open)
  - Sign into the App Store when prompted (2FA may be required)
* The script uses HTTPS for cloning (no SSH setup needed)
* App Store apps will only install after successful App Store sign-in

## Managing the Brewfile

The Brewfile tracks your system's Homebrew packages, casks, and Mac App Store apps. To update it:

```bash
# Dump all installed packages to Brewfile
brew bundle dump --force --describe \
  --file="$(git rev-parse --show-toplevel)/Brewfile"
```

* Use `--force` to overwrite the existing Brewfile
* `--describe` adds helpful comments about each package
* The `$(git rev-parse --show-toplevel)` ensures the Brewfile is created in the repo root

Note: The dump will include VS Code extensions installed via Homebrew. If you prefer to manage VS Code extensions separately, you may want to manually edit the Brewfile to remove the `vscode-extension` lines before committing.

## Troubleshooting

* If GitHub authentication fails, run `gh auth login -p https -w` manually
* If App Store apps fail to install, ensure you're signed into the App Store and run:
  ```bash
  mas account  # verify App Store login
  brew bundle   # retry package installation
  ```