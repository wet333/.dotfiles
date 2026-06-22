#!/usr/bin/env bash
#
# shell/shared/aliases.sh - Shell-agnostic aliases (navigation, listing, safety). Sourced by the shell init scripts.

# --- Navigation --------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias dots='cd "$DOTFILES"'
alias back='cd -'

# --- Listing -----------------------------------------------------------------
alias ls='ls --color=auto -lah'
alias grep='grep --color=auto'
alias clear='clear -x'

# --- Safety ------------------------------------------------------------------
alias rm='rm -i'
alias cp='cp -i'
alias mv='mv -i'
alias mkdir='mkdir -p'
