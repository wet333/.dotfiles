# AGENTS.md

This is a **dotfiles repository**, not an application: there is no test suite, no linter, no typechecker, no CI. The verification step is just running the bash scripts (everything is designed to be idempotent and safe to re-run).

For the high-level overview and design rationale, see `README.md` and `Documentation.md`. This file only covers the small set of facts an agent will miss without help.

## Repository map

| Path | Role |
|---|---|
| `bootstrap.sh` | Fresh-machine bootstrap. Installs git if missing, clones the repo, then `exec install.sh`. Override clone URL/dest/branch via `DOTFILES_REPO` / `DOTFILES_DIR` / `DOTFILES_REF`. |
| `install.sh` | Detects distro (dnf \| apt), seeds `.env` from `.env.example`, then runs every `setup/*.sh` in sorted order. |
| `lib/` | Shared helpers — **sourced, never executed**. `common.sh` (logging, env, file ops), `os.sh` (distro + service), `pkgmanager.sh` (dnf/apt abstraction). |
| `setup/NN-*.sh` | Numbered idempotent steps. Auto-discovered by `install.sh` — adding a new file is enough. |
| `shell/` | Bash config that gets wired into `~/.bashrc` by `setup/08-shell.sh`. `shared/` is shell-agnostic so a future zsh config can reuse it. |

## Commands

Run from the repo root unless noted.

| Goal | Command |
|---|---|
| Full install (Fedora or Ubuntu) | `./install.sh` |
| One step only | `bash setup/NN-name.sh` (e.g. `bash setup/04-docker.sh`) |
| Try one value without editing `.env` | `VAR=value bash setup/NN-name.sh` |
| Shellcheck everything | `shellcheck -x bootstrap.sh install.sh lib/*.sh setup/*.sh shell/bash/init.sh shell/bash/prompt.sh` (no config exists; `-x` follows sources) |

`bootstrap.sh` is only for machines that don't have the repo yet; if `.dotfiles/` already exists it does `git pull --ff-only` and re-execs `install.sh`.

## Conventions for new code

All shell scripts in this repo follow a single template. New `setup/NN-*.sh` files should match it:

```bash
#!/usr/bin/env bash
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES="$(cd "$SCRIPT_DIR/.." && pwd)"

source "$DOTFILES/lib/common.sh"          # always
source "$DOTFILES/lib/os.sh"              # if you need PKG_MGR / OS_FAMILY / enable_service
source "$DOTFILES/lib/pkgmanager.sh"      # if you install packages

detect_os
load_env    # only if the step reads .env values (e.g. git identity, SSH key)
```

Use the abstractions, never raw `dnf` / `apt-get`: `pkg_install`, `pkg_installed`, `pkg_update`, `pkg_upgrade`; `enable_service <name>` for systemd units. `08-shell.sh` is the reference for "no packages, just file edits".

OS detection picks the package manager (`PKG_MGR`), not `OS_ID` — derivatives like Nobara report `ID=nobara` and would fail. Branch on `PKG_MGR` or `OS_FAMILY`, not `OS_ID`.

## Things that will bite you

- **`lib/common.sh` is a stable API.** The README in `Documentation.md` is explicit: append new helpers next to the existing `link_file` / `ensure_block`, but **never edit the existing helpers** — the `setup/` steps depend on their current behavior.
- **`shell/bash/init.sh` is wired into `~/.bashrc` via a guarded block**, not a symlink. The marker is `dotfiles-shell` (see `setup/08-shell.sh`). If you edit `~/.bashrc` by hand, stay outside that block, or it will be wiped on the next `08-shell.sh` run.
- **Java (SDKMAN) and Node (fnm)** both append to `~/.bashrc` and only become available in a new shell. After `05-java.sh` / `06-node.sh`, you must `exec bash` (or just open a new terminal) before `sdk`, `java`, `fnm`, `node`, `pnpm` resolve.
- **`04-docker.sh` adds the current user to the `docker` group.** Group membership only takes effect on the next login, or after `newgrp docker`. `docker run` will keep failing with permission errors until you do that.
- **`shell/bash/prompt.sh` deliberately `unset PROMPT_COMMAND` before assigning its own.** This is to clobber Nobara's vte array that gets set there. If you rewrite the prompt, keep the `unset` line.
- **`.env` is gitignored and seeded from `.env.example` on first install.** `setup/03-git-identity.sh` bails out with a warning (not an error) if the values are still the template placeholders (`Your Name` / `you@example.com`).

## Pointers

- `README.md` — quick start, distro support, install methods.
- `Documentation.md` — full design rationale, layout, step-by-step explanations, why-not-symlinks argument.
- `lib/common.sh` — the helper API (logging, env, `link_file`, `ensure_block`).
- `lib/os.sh` / `lib/pkgmanager.sh` — the `dnf` vs `apt` abstraction.
