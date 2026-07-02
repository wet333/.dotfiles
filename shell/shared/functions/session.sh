#!/usr/bin/env bash
#
# shell/shared/functions/session.sh - Shell session helpers. Sourced by the shell init scripts.

# Replace the current shell with a fresh one — equivalent to closing and reopening the terminal,
# but faster. Re-reads the rc files so any dotfile edits take effect.
# Usage: reload
reload_shell() {
    exec "${SHELL:-/bin/bash}"
}
