# `ai/` — AI harness configs

Configs for the two AI harnesses used alongside the dotfiles: **ClaudeCode**
(`~/.claude/`) and **OpenCode** (`~/.config/opencode/`). Tracked here so they
version with the rest of the repo and deploy onto a fresh machine with one
command.

## Layout

```
ai/
├── install.sh                     standalone deployer (not run by install.sh)
└── config/
    ├── shared/
    │   └── skills/                SKILL.md files, mirrored to ~/.claude/skills/
    │                                (OpenCode reads that path natively too)
    ├── opencode/
    │   ├── opencode.jsonc         copied to ~/.config/opencode/opencode.jsonc
    │   └── agents/                *.md agents, mirrored to ~/.config/opencode/agents/
    └── claude/
        ├── settings.json          copied to ~/.claude/settings.json
        ├── mcp.json               source of truth for ClaudeCode MCP servers
        └── agents/                *.md agents, mirrored to ~/.claude/agents/
```

## Install

```bash
./ai/install.sh
```

- **Standalone** — not invoked by the main `install.sh`. Run whenever you add
  or change a tracked file.
- **Idempotent** — re-running leaves things in the same state. Files with
  unchanged content are skipped; mirrors land on identical bytes.
- **Non-silent destruction** — when a mirrored destination has files that
  don't exist in the repo, they're listed and the destination is moved to
  `.bak` before being recreated.

Existing live configs (`~/.claude/settings.json`, `~/.config/opencode/opencode.jsonc`)
are picked up as the starting point the first time you run the installer.

## How to add things

### New skill (works for both harnesses)

Create `ai/config/shared/skills/<name>/SKILL.md` with the required frontmatter
(`name`, `description`), then run `./ai/install.sh`. The same file is visible
to ClaudeCode and OpenCode.

### New agent

The agent file format differs between the two harnesses, so agents live in
separate dirs:

- **ClaudeCode**: `ai/config/claude/agents/<name>.md` with `name`, `description`,
  optional `tools`, `model`, etc.
- **OpenCode**:   `ai/config/opencode/agents/<name>.md` with `description`,
  `mode`, `prompt`, etc.

If you maintain the same agent on both, just duplicate the file (the bodies
are typically very similar even if frontmatter differs).

### New MCP server

The MCP schemas also differ, so each harness has its own source:

- **OpenCode**: add a server to the `mcp:` block in
  `ai/config/opencode/opencode.jsonc`. Format uses `command: ["...", "..."]`.

  ```json
  {
    "mcp": {
      "context7": {
        "type": "local",
        "command": ["npx", "-y", "@upstash/context7-mcp"],
        "enabled": true
      }
    }
  }
  ```

- **ClaudeCode**: add a server to `mcpServers` in `ai/config/claude/mcp.json`.
  Format uses `command: "string"` plus `args: ["..."]`.

  ```json
  {
    "mcpServers": {
      "context7": {
        "type": "stdio",
        "command": "npx",
        "args": ["-y", "@upstash/context7-mcp"]
      }
    }
  }
  ```

Run `./ai/install.sh` to copy the OpenCode config into place and to register
each ClaudeCode server via `claude mcp add-json --scope user`.

### Configured MCPs (current)

The repo ships with these servers enabled by default. To narrow or drop
any of them, edit the JSON files and re-run the installer.

| Server | Transport | Auth | Notes |
|---|---|---|---|
| `context7` | remote HTTP | none (optional key) | Library docs lookup |
| `gh_grep` | remote HTTP | none | GitHub code search via grep.app |
| `github` | remote HTTP | OAuth on first use | PR/issue/repo operations; needs login |
| `duckduckgo` | local stdio (`npx`) | none | Web/news search via DDG; no API key, conservative rate limits |
| `playwright` | local stdio (`npx`) | none | Browser automation; downloads Chromium on first use |
| `memory` | local stdio (`npx`) | none | Persistent knowledge graph |
| `sequential-thinking` | local stdio (`npx`) | none | Step-by-step planning/reasoning |
| `filesystem` | local stdio (`npx`) | none | Sandboxed FS access; **defaults to `${HOME}`**, narrow it! |
| `everything` | local stdio (`npx`) | none | Reference/test server — exposes all MCP features |
| `postgres` | local stdio (`npx`) | needs `$DATABASE_URL` | Read-only by default; set `ALLOW_WRITES=1` to opt in to writes |

### Required environment variables

Some servers read runtime values from your shell environment. Set these in
`~/.bashrc` (or wherever you keep env vars) before starting ClaudeCode /
OpenCode if you want the server to actually work:

- **`DATABASE_URL`** — connection string for the `postgres` server, e.g.
  `postgresql://readonly:secret@localhost:5432/mydb`. If unset, the server
  registers but every call fails with a connection error.

### LSP / code intelligence

OpenCode activa todos los servidores de lenguaje built-in por la línea
`"lsp": {}` en `opencode.jsonc`. No se necesita config por lenguaje:
cada servidor arranca solo cuando OpenCode abre un archivo con la
extensión soportada y el binario (o auto-installer) está disponible.
Cero costo cuando no hay archivos del lenguaje en uso.

ClaudeCode no tiene un equivalente directo en `settings.json` (no
existe un bloque `lsp`). El code intelligence en ClaudeCode se hace
vía plugins de la marketplace `claude-plugins-official` (`typescript-lsp`,
`pyright-lsp`, `gopls-lsp`, etc.) y requiere un `/plugin install` por
dev por la fricción del trust prompt — por eso este repo no los
gestiona.

### Narrowing `filesystem`

The filesystem MCP refuses to start without at least one absolute directory
in `args`. The default `${HOME}` / `{env:HOME}` is too broad — it lets the
agent read your `.ssh` keys. To narrow it, edit the `filesystem` entry in
both JSONs:

```diff
- ["-y", "@modelcontextprotocol/server-filesystem", "${HOME}"]
+ ["-y", "@modelcontextprotocol/server-filesystem", "${HOME}/projects", "${HOME}/notes"]
```

Same shape for OpenCode (uses `{env:HOME}` instead of `${HOME}`).

## Why not symlinks?

Symlinks would let the repo be the single source of truth, but they make
hand-edits through the harnesses' UIs silently vanish on the next run —
which is the opposite of what most users expect. This layout instead *copies*
tracked files onto the live config: any change you make through a harness
gets reverted the next time `install.sh` runs, so the repo is unambiguous.

## Why share skills but not agents or MCPs?

- **Skills** use the same `SKILL.md` format with the same frontmatter on both
  harnesses, and OpenCode's discovery docs explicitly include
  `~/.claude/skills/`, so one file works for both.
- **Agents** and **MCPs** have meaningfully different schemas (ClaudeCode's
  `name`/`tools`/`model` vs OpenCode's `description`/`mode`/`prompt`; ClaudeCode's
  `command: string` + `args: array` vs OpenCode's `command: array`). Keeping
  them per-harness avoids pretending the schemas match.
