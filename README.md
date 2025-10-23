## 🚀 Quick Start

Paste this command into a fresh macOS terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/jonathan-grs/mac-bootstrap/main/bootstrap.sh | /bin/sh
````

### What this does

1. Installs **Xcode Command Line Tools** (for `git` and compilers).
2. Installs **Homebrew** (package manager).
3. Installs **yadm** (dotfiles manager) and **GitHub CLI (`gh`)**.
4. Opens a **GitHub device login** (secure, no PAT or SSH key required).
5. Clones your **private dotfiles repo** and runs its bootstrap script.

## 🧠 Notes

* The script is **idempotent** — you can safely run it again anytime.
* After setup, open the **App Store** once and sign in, then run:

  ```bash
  yadm bootstrap
  ```

  to finish installing Mac App Store apps.
