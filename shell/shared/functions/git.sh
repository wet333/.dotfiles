#!/usr/bin/env bash
#
# shell/shared/functions/git.sh - Git/GitHub helpers. Sourced by the shell init scripts.

# Clone every public repository owned by a GitHub user into a local directory.
# Repo list comes from scraping the public profile page (no API, no gh, no token required).
# SSH URL is built locally as git@github.com:<user>/<name>.git.
# Tries SSH first, then HTTPS per repo; if both fail, the repo is skipped and the run continues.
# Usage: github_full_clone_ssh <github-url-or-user> [<dest-dir>]
# Examples:
#   github_full_clone_ssh https://github.com/wet333
#   github_full_clone_ssh wet333 ~/code/wet333
github_full_clone_ssh() {
    local raw="${1:-}"
    local dest="${2:-}"

    if [ -z "$raw" ]; then
        echo "github_full_clone_ssh: missing argument" >&2
        echo "Usage: github_full_clone_ssh <github-url-or-user> [<dest-dir>]" >&2
        return 2
    fi

    local user
    if [[ "$raw" =~ ^git@github\.com:([^/]+)/?$ ]]; then
        user="${BASH_REMATCH[1]}"
    elif [[ "$raw" =~ ^https?://github\.com/([^/]+)/?$ ]]; then
        user="${BASH_REMATCH[1]}"
    elif [[ "$raw" =~ ^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$ ]]; then
        user="$raw"
    else
        echo "github_full_clone_ssh: cannot parse GitHub user from '$raw'" >&2
        return 2
    fi

    if [ -z "$dest" ]; then
        dest="$HOME/github_repos"
    fi

    if [ -e "$dest" ] && [ ! -d "$dest" ]; then
        echo "github_full_clone_ssh: '$dest' exists and is not a directory" >&2
        return 1
    fi
    mkdir -p -- "$dest" || return 1

    if [ ! -f "$HOME/.ssh/id_ed25519" ] && [ -z "${SSH_AUTH_SOCK:-}" ]; then
        echo "github_full_clone_ssh: warning - no ~/.ssh/id_ed25519 and no ssh-agent; SSH clones will likely fall back to HTTPS" >&2
    fi

    if ! command -v curl >/dev/null 2>&1; then
        echo "github_full_clone_ssh: 'curl' is required" >&2
        return 1
    fi

    local ua="Mozilla/5.0 (X11; Linux x86_64) dotfiles-github_full_clone_ssh"
    local -a repos=()
    local -A seen=()
    local page=1 new found
    while [ "$page" -le 50 ]; do
        local html
        if ! html=$(curl -fsSL -A "$ua" "https://github.com/${user}?tab=repositories&page=${page}"); then
            if [ "$page" -eq 1 ]; then
                echo "github_full_clone_ssh: failed to fetch https://github.com/${user}?tab=repositories" >&2
                return 1
            fi
            break
        fi
        new=0
        while IFS= read -r found; do
            [ -z "$found" ] && continue
            [ -n "${seen[$found]:-}" ] && continue
            seen[$found]=1
            repos+=("$found")
            new=1
        done < <(printf '%s' "$html" \
                | grep -oE "href=\"/${user}/[A-Za-z0-9._-]+\"" \
                | sed -e "s|href=\"/${user}/||" -e 's|"$||')
        [ "$new" -eq 0 ] && break
        page=$((page+1))
    done

    local total=${#repos[@]}
    if [ "$total" -eq 0 ]; then
        echo "github_full_clone_ssh: no repos found for '$user'"
        return 0
    fi

    local token="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
    local cloned=0 skipped=0 failed=0
    local i name target ssh_url https_url
    for i in "${!repos[@]}"; do
        name="${repos[$i]}"
        target="$dest/$name"
        ssh_url="git@github.com:${user}/${name}.git"

        if [ -d "$target" ]; then
            printf '[%d/%d] skip   exists   %s\n' "$((i+1))" "$total" "$name"
            skipped=$((skipped+1))
            continue
        fi

        printf '[%d/%d] clone  ssh      %s ... ' "$((i+1))" "$total" "$name"
        if git clone -- "$ssh_url" "$target" >/dev/null 2>&1; then
            echo "ok"
            cloned=$((cloned+1))
            continue
        fi

        printf "fail - trying https ... "
        if [ -n "$token" ]; then
            https_url="https://x-access-token:${token}@github.com/${user}/${name}.git"
        else
            https_url="https://github.com/${user}/${name}.git"
        fi
        if git clone -- "$https_url" "$target" >/dev/null 2>&1; then
            echo "ok"
            cloned=$((cloned+1))
        else
            echo "fail"
            printf '[%d/%d] FAIL   ssh+https %s\n' "$((i+1))" "$total" "$name"
            failed=$((failed+1))
        fi
    done

    echo "github_full_clone_ssh: done - $cloned cloned, $skipped skipped, $failed failed - $dest"
    return 0
}
