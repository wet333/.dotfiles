#!/usr/bin/env bash
#
# ai/install.sh - Deploy the tracked AI configs (skills, agents, settings)
# onto the live harness config locations. Standalone — not picked up by
# install.sh. Idempotent: re-running leaves things in the same state.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "$SCRIPT_DIR/.." && pwd)"
AI="$REPO/ai"
CONFIG="$AI/config"

# --- Locate helpers ----------------------------------------------------------
#
# Prefer a sibling lib/ (when run from inside the dotfiles repo). Allow
# override via DOTFILES_LIB for unusual layouts.
if [ -n "${DOTFILES_LIB:-}" ]; then
    LIB="$DOTFILES_LIB"
elif [ -d "$REPO/lib" ]; then
    LIB="$REPO/lib"
else
    error "ai/install.sh: could not locate lib/. Set DOTFILES_LIB=... or run from inside the dotfiles repo."
    exit 1
fi

source "$LIB/common.sh"

# --- Paths -------------------------------------------------------------------

OPENCODE_DIR="$HOME/.config/opencode"
CLAUDE_DIR="$HOME/.claude"

# --- Seeding ------------------------------------------------------------------
#
# Populate the repo's ai/config/ from the live harness state on the very
# first run, so the user doesn't start with empty templates that wipe their
# current setup. Existing tracked files are never overwritten.

log "Seeding AI config from current harness state (only if missing)..."

if [ ! -e "$CONFIG/opencode/opencode.jsonc" ] && [ -e "$OPENCODE_DIR/opencode.jsonc" ]; then
    cp "$OPENCODE_DIR/opencode.jsonc" "$CONFIG/opencode/opencode.jsonc"
    info "seeded $CONFIG/opencode/opencode.jsonc from $OPENCODE_DIR/opencode.jsonc"
elif [ ! -e "$CONFIG/opencode/opencode.jsonc" ]; then
    info "no live opencode.jsonc found; the existing repo template will be used"
fi

if [ ! -e "$CONFIG/claude/settings.json" ] && [ -e "$CLAUDE_DIR/settings.json" ]; then
    cp "$CLAUDE_DIR/settings.json" "$CONFIG/claude/settings.json"
    info "seeded $CONFIG/claude/settings.json from $CLAUDE_DIR/settings.json"
elif [ ! -e "$CONFIG/claude/settings.json" ]; then
    info "no live claude/settings.json found; the existing repo template will be used"
fi

[ -e "$CONFIG/claude/mcp.json" ] || {
    printf '{\n  "mcpServers": {}\n}\n' > "$CONFIG/claude/mcp.json"
    info "created $CONFIG/claude/mcp.json template"
}

for d in \
    "$CONFIG/shared/skills" \
    "$CONFIG/opencode/agents" \
    "$CONFIG/claude/agents"
do
    [ -d "$d" ] || mkdir -p "$d"
done

# --- Files --------------------------------------------------------------------

log "Copying tracked config files into place..."

copy_replace "$CONFIG/opencode/opencode.jsonc" "$OPENCODE_DIR/opencode.jsonc"
copy_replace "$CONFIG/claude/settings.json"     "$CLAUDE_DIR/settings.json"

# Global rules (OpenCode reads ~/.config/opencode/AGENTS.md; ClaudeCode reads
# ~/.claude/CLAUDE.md). Same content for both — single source, two destinations.
copy_replace "$CONFIG/shared/system-rules.md"   "$OPENCODE_DIR/AGENTS.md"
copy_replace "$CONFIG/shared/system-rules.md"   "$CLAUDE_DIR/CLAUDE.md"

# --- Directory trees ---------------------------------------------------------

log "Mirroring tracked directory trees into place..."

mirror_dir "$CONFIG/shared/skills"   "$CLAUDE_DIR/skills"
mirror_dir "$CONFIG/opencode/agents" "$OPENCODE_DIR/agents"
mirror_dir "$CONFIG/claude/agents"   "$CLAUDE_DIR/agents"

# --- Claude MCP servers ------------------------------------------------------
#
# ClaudeCode stores user-scope MCPs in ~/.claude.json, which is managed by
# `claude mcp ...`. We treat ai/config/claude/mcp.json as the source of
# truth and register every server listed there.

apply_claude_mcps() {
    if ! have claude; then
        warning "claude CLI not on PATH; skipping MCP registration"
        return 0
    fi

    if ! have jq; then
        warning "jq not on PATH; skipping ClaudeCode MCP registration (install jq to enable)"
        return 0
    fi

    local mcp_file="$CONFIG/claude/mcp.json"
    [ -f "$mcp_file" ] || { info "no $mcp_file; nothing to register"; return 0; }

    local names
    names="$(jq -r '.mcpServers | keys[]' "$mcp_file" 2>/dev/null || true)"
    if [ -z "$names" ]; then
        info "no MCP servers declared in $mcp_file"
        return 0
    fi

    log "Registering ClaudeCode MCP servers from $mcp_file..."

    local name payload existing added=0 skipped=0
    for name in $names; do
        payload="$(jq -c --arg n "$name" '.mcpServers[$n]' "$mcp_file")"
        if existing="$(claude mcp get "$name" 2>/dev/null)"; then
            info "  already registered: $name"
            skipped=$((skipped + 1))
        else
            claude mcp add-json --scope user "$name" "$payload" >/dev/null
            success "  registered: $name"
            added=$((added + 1))
        fi
    done

    info "ClaudeCode MCPs: $added newly registered, $skipped already present"
}

apply_claude_mcps

# --- Summary ------------------------------------------------------------------

success "AI configs deployed."
info "Re-run '$SCRIPT_DIR/install.sh' anytime; it's idempotent."
