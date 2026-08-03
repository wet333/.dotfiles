# Global Coding Rules

These rules apply to every session, regardless of workspace.

## Shell scripting

**Do not use heredocs** in any shell or terminal script. This applies to:

- Bash scripts (`.sh` files, scripts run via the Bash tool)
- One-liner shell snippets pasted into the bash tool
- Setup scripts, installer hooks, and dotfiles automation

Forbidden:

- `<<EOF`, `<<'EOF'`, `<<-EOF`, and any variant (quoted/unquoted, leading-dash)
- `<<<word` here-strings

Use instead: multiple `echo` / `printf` lines, one `printf '%s\n' a b c` for a few lines, or a separate script file the outer script invokes.
