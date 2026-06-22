#!/usr/bin/env bash
#
# shell/bash/init.sh - Bash entry point: load shared config then bash-specific bits.
# Sourced from ~/.bashrc via the dotfiles-shell block. Defensive and safe to re-source.

: "${DOTFILES:=$HOME/.dotfiles}"

# Shared, shell-agnostic config (env, then aliases).
for _f in "$DOTFILES/shell/shared/env.sh" "$DOTFILES/shell/shared/aliases.sh"; do
    [ -r "$_f" ] && . "$_f"
done

# Shared functions.
for _f in "$DOTFILES"/shell/shared/functions/*.sh; do
    [ -r "$_f" ] && . "$_f"
done

# Bash-specific.
[ -r "$DOTFILES/shell/bash/prompt.sh" ] && . "$DOTFILES/shell/bash/prompt.sh"

unset _f
