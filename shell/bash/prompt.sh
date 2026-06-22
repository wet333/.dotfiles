#!/usr/bin/env bash
#
# shell/bash/prompt.sh - Segmented, git-aware bash prompt. Sourced by shell/bash/init.sh.
# Renders: [time]--[user@host]--[cwd]--[branch]--> with purple symbols and cyan data.

# Echo the current git branch, or nothing when not inside a repo.
# Usage: __git_branch
__git_branch() {
    git branch --show-current 2>/dev/null
}

# Rebuild PS1 each prompt so the git branch stays current.
# Usage: __set_bash_prompt
__set_bash_prompt() {
    local p='\[\e[35m\]'   # purple: brackets and symbols
    local d='\[\e[36m\]'   # cyan: data
    local r='\[\e[0m\]'    # reset

    local branch git_seg=""
    branch="$(__git_branch)"
    [ -n "$branch" ] && git_seg="--${p}[${d}${branch}${p}]"

    PS1="${p}[${d}\t${p}]--[${d}\u@\h${p}]--[${d}\w${p}]${git_seg}${p}--> ${r}"
}

# Drop any existing PROMPT_COMMAND (e.g. Nobara's vte array) so ours fully takes over.
unset PROMPT_COMMAND
PROMPT_COMMAND=__set_bash_prompt
