# Design: arch-mcp npm publish + SKILL.md wiring

**Date:** 2026-06-23
**Status:** Approved

## Summary

Publish `@valentinlineiro/arch-mcp` to npm and wire it into the arch-protocol plugin so users get the MCP server automatically on plugin install. Replace all raw Bash state operations in SKILL.md with MCP tool calls. This makes the MCP server a hard dependency of the skill.

## Section 1 — Distribution pipeline

**arch-mcp repo:**
- Create GitHub remote `valentinlineiro/arch-mcp`
- Bump version `0.1.0` → `1.0.0`
- Publish to npm as `@valentinlineiro/arch-mcp`

**arch-protocol plugin.json:**
Add `mcpServers` inline (object form, per Claude Code plugin reference):
```json
"mcpServers": {
  "arch-mcp": {
    "command": "npx",
    "args": ["-y", "@valentinlineiro/arch-mcp@1.0.0"]
  }
}
```
Version pin is exact (`1.0.0`) for reproducible installs. Future arch-mcp releases require a pin bump + arch-protocol version bump.

**arch-protocol version:** `1.9.2` → `2.0.0` — major bump because the MCP hard dependency is a breaking change for existing users without the server.

**State file ownership:** arch-mcp reads/writes `~/.arch/*` — the same files the Bash commands used (`~/.arch/anchor_state`, `~/.arch/solo_declared_*`, `~/.arch/shift.json`, `~/.arch/retro.md`). The filesystem is still the backing store; the MCP server is the exclusive write path. SKILL.md must never read these files directly — always call the MCP tool and use the returned value.

## Section 2 — SKILL.md wiring

Six Bash state operations are replaced with MCP tool calls. No Bash fallbacks — hard dependency.

| Step | Current Bash | MCP tool | Return value used |
|------|-------------|----------|-------------------|
| ANCHOR | `echo ... > ~/.arch/anchor_state` | `mcp__arch-mcp__arch_anchor` | returned hash stored as ANCHOR_HASH |
| SOLO | `touch ~/.arch/solo_declared_<hash>` | `mcp__arch-mcp__arch_solo_declare` | none |
| GATE | reads `~/.arch/shift.json` | `mcp__arch-mcp__arch_shift_read` | returned `session_task_count` used for context-decay check |
| LOG (omissions) | writes `~/.arch/shift.json` | `mcp__arch-mcp__arch_shift_write` | none |
| LOG (M/L count) | increments `session_task_count` in file | `mcp__arch-mcp__arch_session_increment` | none |
| session start | n/a (new) | `mcp__arch-mcp__arch_version` | returned `protocol_version` surfaced in evolve check |

`arch_retro_append` is out of scope — the Stop hook owns retro writes and already works.

**Instruction design rule:** SKILL.md must explicitly tell Claude to capture return values from MCP tool results. Example: "call `mcp__arch-mcp__arch_shift_read` and use the returned `session_task_count` value" — not "read `~/.arch/shift.json`." The MCP server owns the state; the skill must not bypass it with direct file reads.

## Section 3 — Version strategy & testing

**Versions:**
- `arch-mcp`: `0.1.0` → `1.0.0`
- `arch-protocol`: `1.9.2` → `2.0.0`

**Test sequence (end-to-end, live session):**
1. **ANCHOR** — run ANCHOR step, verify `arch_anchor` is called and returns hash used as ANCHOR_HASH
2. **SOLO** — declare SOLO, verify `arch_solo_declare` is called with correct hash
3. **shift_read isolation** — call `mcp__arch-mcp__arch_shift_read` directly, verify it returns a valid `session_task_count`
4. **GATE (context-decay)** — run a full GATE with `session_task_count >= 5` pre-set, verify the decay warning fires using the value returned by `arch_shift_read`
5. **LOG (omissions)** — write a LOG with an `omit:` key, verify `arch_shift_write` persists the counter
6. **LOG (M/L count)** — complete an M task, verify `arch_session_increment` fires
7. **Version** — call `mcp__arch-mcp__arch_version`, verify both `mcp_version: "1.0.0"` and `protocol_version: "2.0.0"` are returned

## Two-repo sync convention

When arch-mcp releases a new version:
1. `npm publish` from arch-mcp repo
2. Update version pin in arch-protocol `plugin.json` `mcpServers.arch-mcp.args`
3. Bump arch-protocol version (patch if behavior-compatible, minor/major if breaking)
4. Push arch-protocol
