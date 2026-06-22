# Documentation

Detailed companion to `README.md`. For a quick start, read the README.

## What it is

This is my personal setup for a new Linux machine. Run one command and it goes from a blank
install to a ready-to-use dev environment — packages, SSH, git, Docker, language toolchains and my
shell config, all in place.

A few things make it pleasant to live with:

- **It works on Fedora and Ubuntu.** Scripts never call `dnf` or `apt` directly. They go through
  small helpers (`pkg_install`, `enable_service`, …) that figure out the right command, so the same
  script runs on either distro.
- **You can run it as many times as you want.** Every step checks the current state before doing
  anything, so re-running never breaks a machine that's already set up.
- **Your settings live in one place.** Personal values (git name/email, SSH options) go in a single
  `.env` file that's kept out of git.
- **It won't clobber your files.** Anything it touches is backed up first (`*.bak`), and edits to
  files like `~/.bashrc` go in a clearly marked block it can update later.

The whole thing is just small numbered scripts. `bootstrap.sh` gets the repo onto a fresh machine,
`install.sh` runs the `setup/` steps in order, and each step also works on its own if you only want
one piece.

## How to run

| Command | Use it when |
|---------|-------------|
| `curl -fsSL …/bootstrap.sh` piped to `bash` | New machine, repo not cloned yet (installs git, clones, runs installer). |
| `./install.sh` | Repo present; run the full setup. |
| `bash setup/NN-name.sh` | Run/re-apply a single step. |
| `VAR=value bash setup/NN-name.sh` | Try a value once without editing `.env`. |

For a permanent config change, edit `.env`. Everything is safe to re-run.

## Layout

The repo has three kinds of things: a couple of entry-point scripts at the top, reusable helpers in
`lib/`, and the actual installation steps in `setup/`.

**Entry points** — what you run:

- `bootstrap.sh` — gets the repo onto a fresh machine (installs git, clones, then runs `install.sh`).
- `install.sh` — runs all the `setup/` steps in order.

**`lib/`** — shared helpers the steps call (never run directly):

- `common.sh` — logging, `.env` loading, symlinks, the guarded-block editor for files like `~/.bashrc`.
- `os.sh` — detects the distro and manages system services.
- `pkgmanager.sh` — installs/updates packages without caring whether it's `dnf` or `apt`.

**`setup/`** — the numbered steps (`00`…`08`), each idempotent and runnable on its own.

**Config & shell:**

- `.env` / `.env.example` — your personal values (`.env` is git-ignored).
- `shell/` — shared aliases/functions/env plus the bash config (zsh planned).

## Setup steps

- **`00-system-update.sh`** — refresh metadata + upgrade.
- **`01-core-packages.sh`** — everyday CLI utilities.
- **`02-ssh.sh`** — openssh-server + service, `~/.ssh` (700), generates a key only if absent.
- **`03-git-identity.sh`** — global git identity + defaults from `.env`.
- **`04-docker.sh`** — Docker CE + compose, service, adds user to `docker` group.
- **`05-java.sh` / `06-node.sh`** — Java (SDKMAN) and Node.js (fnm) toolchains.
- **`07-c.sh`** — C/C++ toolchain.
- **`08-shell.sh`** — wires `shell/bash/init.sh` into `~/.bashrc` via `ensure_block`.

**Add a step:** create `setup/NN-name.sh`, source `lib/common.sh` + `lib/os.sh`, call `detect_os`
(and `load_env` if needed), use the API, keep it idempotent. `install.sh` picks it up automatically.

## Shell

Split so a future zsh config can reuse the shared parts:

- **`shared/env.sh`** — env vars (`EDITOR`/`VISUAL`, `~/.local/bin` on `PATH`).
- **`shared/aliases.sh`** — navigation (`..`, `dots`, `back`), listing, safety (`rm -i`, …).
- **`shared/functions/fs.sh`** — `mkcd`, `extract`.
- **`bash/prompt.sh`** — git-aware prompt via `PROMPT_COMMAND`.
- **`bash/init.sh`** — entry point sourcing `shared/*` then `bash/prompt.sh`; wired by `08-shell.sh`.

## Roadmap

- **zsh** — `shell/zsh/` init + prompt reusing `shell/shared/`, wired via `ensure_block`.
