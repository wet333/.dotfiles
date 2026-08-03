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
| `ai/` | **Separate deploy track** for ClaudeCode / OpenCode configs. Has its own `ai/install.sh`; **not** invoked by `./install.sh`. |

## Commands

Run from the repo root unless noted.

| Goal | Command |
|---|---|
| Full install (Fedora or Ubuntu) | `./install.sh` |
| One step only | `bash setup/NN-name.sh` (e.g. `bash setup/04-docker.sh`) |
| Try one value without editing `.env` | `VAR=value bash setup/NN-name.sh` |
| Deploy / re-deploy AI harness configs | `./ai/install.sh` |
| Shellcheck everything | `shellcheck -x bootstrap.sh install.sh ai/install.sh lib/*.sh setup/*.sh shell/bash/init.sh shell/bash/prompt.sh` (no config exists; `-x` follows sources) |

The AI config installer is **standalone** — it will not run as part of `./install.sh`. Run it explicitly after editing anything under `ai/config/`.

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

- **`lib/common.sh` is a stable API.** The README in `Documentation.md` is explicit: append new helpers (`copy_replace`, `mirror_dir`, …) next to the existing `link_file` / `ensure_block`, but **never edit the existing helpers** — the `setup/` steps depend on their current behavior.
- **`shell/bash/init.sh` is wired into `~/.bashrc` via a guarded block**, not a symlink. The marker is `dotfiles-shell` (see `setup/08-shell.sh`). If you edit `~/.bashrc` by hand, stay outside that block, or it will be wiped on the next `08-shell.sh` run.
- **Java (SDKMAN) and Node (fnm)** both append to `~/.bashrc` and only become available in a new shell. After `05-java.sh` / `06-node.sh`, you must `exec bash` (or just open a new terminal) before `sdk`, `java`, `fnm`, `node`, `pnpm` resolve.
- **`04-docker.sh` adds the current user to the `docker` group.** Group membership only takes effect on the next login, or after `newgrp docker`. `docker run` will keep failing with permission errors until you do that.
- **The `filesystem` MCP server defaults to `${HOME}` / `{env:HOME}`** in both `ai/config/opencode/opencode.jsonc` and `ai/config/claude/mcp.json`. That gives the agent access to `.ssh/`, `.aws/`, etc. Narrow it to specific subdirs (`"${HOME}/projects"`) before deploying.
- **The `postgres` MCP needs `DATABASE_URL` exported in the shell** that starts the harness; if it's unset the server registers but every call fails.
- **`ai/install.sh` is copy-and-replace, not symlinks, on purpose.** Symlinks would let edits made through a harness UI silently vanish on the next run. The "repo is the single source of truth" trade-off is the point — don't change it without reading `ai/README.md` first.
- **Skills are shared between ClaudeCode and OpenCode** via `ai/config/shared/skills/` (it gets mirrored to `~/.claude/skills/`, and OpenCode discovers that path too). **Agents and MCPs are per-harness** because their schemas differ (ClaudeCode: `name`/`tools`/`model`, `command: "string"` + `args: [...]`; OpenCode: `description`/`mode`/`prompt`, `command: [...]` as a single array). Don't try to share those.
- **`shell/bash/prompt.sh` deliberately `unset PROMPT_COMMAND` before assigning its own.** This is to clobber Nobara's vte array that gets set there. If you rewrite the prompt, keep the `unset` line.
- **`.env` is gitignored and seeded from `.env.example` on first install.** `setup/03-git-identity.sh` bails out with a warning (not an error) if the values are still the template placeholders (`Your Name` / `you@example.com`).

## Pointers

- `README.md` — quick start, distro support, install methods.
- `Documentation.md` — full design rationale, layout, step-by-step explanations, why-not-symlinks argument.
- `ai/README.md` — how to add skills, agents, MCP servers; current MCP inventory; the filesystem-narrowing recipe.
- `lib/common.sh` — the helper API (logging, env, `link_file`, `ensure_block`, `copy_replace`, `mirror_dir`).
- `lib/os.sh` / `lib/pkgmanager.sh` — the `dnf` vs `apt` abstraction.
