#!/usr/bin/env bash
#
# shell/shared/functions/ssh.sh - SSH public key helper. Sourced by the shell init scripts.

# Print the public SSH key; with -c/--copy, also put it on the clipboard.
# Usage: ssh_getkey        # print
#        ssh_getkey -c     # print AND copy
ssh_getkey() {
    local pub="$HOME/.ssh/id_ed25519.pub"
    if [ ! -f "$pub" ]; then
        echo "ssh_getkey: no public key at $pub" >&2
        return 1
    fi

    cat -- "$pub"

    case "${1:-}" in
        -c|--copy)
            if   command -v wl-copy >/dev/null 2>&1; then wl-copy < "$pub" && echo "(copied via wl-copy)"
            elif command -v xclip   >/dev/null 2>&1; then xclip -selection clipboard < "$pub" && echo "(copied via xclip)"
            elif command -v xsel    >/dev/null 2>&1; then xsel --clipboard --input < "$pub" && echo "(copied via xsel)"
            elif command -v pbcopy  >/dev/null 2>&1; then pbcopy < "$pub" && echo "(copied via pbcopy)"
            else
                echo "ssh_getkey: no clipboard tool found (install xclip, xsel, or wl-copy)" >&2
                return 1
            fi
            ;;
    esac
}
