# .dotfiles

My personal setup for a fresh Linux machine. Run one command and it goes from a blank install to a
ready-to-use dev environment — packages, SSH, git, Docker, language toolchains and my shell config.

Works on **Fedora (dnf)** and **Ubuntu (apt)** (and derivatives like Nobara). It's just small
numbered scripts, and you can run the whole thing or any single step as many times as you want —
re-running never breaks an already-configured machine.

## Install

On a brand-new machine (no repo yet):

```bash
curl -fsSL https://raw.githubusercontent.com/wet333/dotfiles/master/bootstrap.sh | bash
```

Or if you've already cloned it:

```bash
git clone https://github.com/wet333/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Your personal values (git name/email, SSH options) live in a single `.env` at the repo root. The
first run copies `.env.example` → `.env`; edit it with your values and re-run.

## What it sets up

- System update + core CLI packages
- SSH key + server
- Git identity and sane defaults
- Docker CE (engine + compose)
- Java, Node.js and C/C++ toolchains
- Shell config: git-aware prompt, aliases, functions (bash today, zsh planned)

## More

See [`Documentation.md`](Documentation.md) for how it all fits together and the reasoning behind it.
