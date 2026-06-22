#!/usr/bin/env bash
#
# shell/shared/env.sh - Shell-agnostic environment variables. Sourced by the shell init scripts.

export EDITOR=vim
export VISUAL=vim

# Prepend ~/.local/bin if present and not already on PATH.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) [ -d "$HOME/.local/bin" ] && PATH="$HOME/.local/bin:$PATH" ;;
esac
