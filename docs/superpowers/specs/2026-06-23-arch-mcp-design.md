# ARCH MCP Server — Design Spec
*2026-06-23*

---

## 1. Project Structure

Separate TypeScript project: `arch-mcp` (GitHub repo `valentinlineiro/arch-mcp`).
Published as `@valentinlineiro/arch-mcp` on npm.

```
arch-mcp/
  src/
    index.ts                  # MCP server entry, registers all tools
    tools/
      anchor.ts               # arch_anchor
      shift.ts                # arch_shift_read, arch_shift_write
      retro.ts                # arch_retro_append
      solo.ts                 # arch_solo_declare
      version.ts              # arch_version
    lib/
      paths.ts                # dual-resolver: resolveGlobal() + resolveProject()
      exec.ts                 # thin Bash wrapper
    schema/
      shift.ts                # ShiftState interface — canonical definition
      conventions.ts          # soloMarkerName(hash) — naming contract
  tests/
    tools/
      anchor.test.ts
      shift.test.ts
      retro.test.ts
      solo.test.ts
    lib/
      paths.test.ts
  package.json
  tsconfig.json
  README.md
```

**Dependency:** `@modelcontextprotocol/sdk` only. No ARCH-internal runtime dependencies.

---

## 2. Tool Contracts

All tools return the standard MCP response envelope:

```typescript
type Ok<T>  = { success: true;  data: T }
type Err    = { success: false; error: string }
type Result<T> = Ok<T> | Err
```

### `arch_anchor`

Runs `git status --short` and `git rev-parse HEAD`. Writes the anchor state to `~/.arch/anchor_state`.

```
Input:  {}
Output: { dirty: boolean; hash: string; uncommitted_files: string[] }
```

The skill holds `hash` in context as `ANCHOR_HASH`. No re-read needed.

### `arch_shift_read`

Reads `~/.arch/shift.json`. Creates the file with default `ShiftState` if absent.

```
Input:  {}
Output: ShiftState
```

### `arch_shift_write`

Writes the provided `ShiftState` object to `~/.arch/shift.json`.

```
Input:  { state: ShiftState }
Output: { written: true }
```

### `arch_retro_append`

Appends a LOG block to the correct retro file. Chooses `~/.arch/retro.md` (global) or `.arch/retro.md` (project) based on whether `.arch/` exists in the current working directory.

```
Input:  { scope: "global" | "project"; content: string }
Output: { file: string; appended: true }
```

`scope` is the primary parameter name (`target` is not used).

### `arch_solo_declare`

Touches the solo marker file `~/.arch/solo_declared_<hash>`. Equivalent to the current shell one-liner; surfaces errors as structured failures instead of silent exit codes.

```
Input:  { hash: string }
Output: { marker_path: string; created: true }
```

**Coupling note:** The marker file name is `soloMarkerName(hash)` from `schema/conventions.ts`. The `on-pre-tool-write.sh` hook reads this path using the same naming convention — the hook and this tool share a contract, documented in `conventions.ts`. If the naming convention changes, both must be updated together.

### `arch_version`

Returns the MCP server version and the protocol version from the installed SKILL.md (reads `~/.claude/plugins/cache/arch-protocol/…/plugin.json`).

```
Input:  {}
Output: { mcp_version: string; protocol_version: string | null }
```

`protocol_version` is `null` if the plugin isn't installed. The skill can surface a compatibility warning when the two drift.

---

## 3. lib Layer

### `paths.ts`

Single source of truth for all file path resolution. No tool or schema file computes paths directly.

```typescript
export function resolveGlobal(filename: string): string
// Returns: ~/.arch/<filename>
// Always resolves to the user's home directory.

export function resolveProject(filename: string): string | null
// Returns: .arch/<filename> relative to CWD, or null if .arch/ doesn't exist.
// Tools that need project-scope behavior call this first and fall back to resolveGlobal().
```

`arch_retro_append` uses `resolveProject()` first; if it returns `null`, uses `resolveGlobal()`. This mirrors the existing `retro.md` dual-file behavior.

### `exec.ts`

Thin wrapper around `child_process.execSync`. Captures stdout/stderr, maps non-zero exit codes to structured errors, and normalises output encoding.

```typescript
export function run(cmd: string, cwd?: string): { stdout: string; stderr: string }
// Throws ExecError on non-zero exit.
```

`arch_anchor` is the only tool that calls `exec.ts` directly (for `git status --short` and `git rev-parse HEAD`). Other tools use `fs` operations only.

---

## 4. Schema Layer

### `schema/shift.ts`

Canonical TypeScript definition of the shift state. This is the single source of truth — SKILL.md references it by name rather than re-specifying the JSON shape.

```typescript
export interface ShiftState {
  omissions: {
    skip_gate: number;
    skip_anchor: number;
    skip_solo: number;
    skip_log: number;
    undeclared_read: number;
    scope_creep: number;
  };
  last_omission_cleared: string | null;
  log_count_at_last_evolve: number;
  session_task_count: number;
}

export const DEFAULT_SHIFT_STATE: ShiftState = {
  omissions: {
    skip_gate: 0,
    skip_anchor: 0,
    skip_solo: 0,
    skip_log: 0,
    undeclared_read: 0,
    scope_creep: 0,
  },
  last_omission_cleared: null,
  log_count_at_last_evolve: 0,
  session_task_count: 0,
};
```

When SKILL.md adds a new field (as `session_task_count` was added in v1.9.0), this interface is the one place to update. `arch_shift_read` uses `DEFAULT_SHIFT_STATE` to backfill missing fields on existing files — forward compatibility without a migration.

### `schema/conventions.ts`

Naming conventions shared between the MCP server and the hook scripts.

```typescript
export function soloMarkerName(hash: string): string {
  return `solo_declared_${hash}`;
}
```

`arch_solo_declare` calls this to compute the filename. The `on-pre-tool-write.sh` hook uses the same convention (as a shell pattern). This file documents the contract; shell scripts can't import it, but any change here must propagate to the hook manually — that coupling is explicit and intentional.

---

## 5. SKILL.md Integration Mapping

The MCP server replaces the current inline shell commands. The skill's prose instructions stay unchanged; only the implementation mechanism changes.

| Current SKILL.md command | Replaced by |
|---|---|
| `git status --short` + `git rev-parse HEAD` + `anchor_state` write | `arch_anchor` |
| `cat ~/.arch/shift.json` + manual JSON parse | `arch_shift_read` |
| Write updated shift.json | `arch_shift_write` |
| Append to `~/.arch/retro.md` or `.arch/retro.md` | `arch_retro_append` |
| `touch ~/.arch/solo_declared_<hash>` | `arch_solo_declare` |

**What the skill holds in context:** After `arch_anchor`, the skill holds `ANCHOR_HASH = result.data.hash`. This is not re-read from `anchor_state` during EYES — the in-context value is authoritative for the session.

**What stays in the hook:** `on-pre-tool-write.sh` checks for the solo marker file using the `soloMarkerName` pattern. This enforcement lives outside the MCP server by design — the server provides the `arch_solo_declare` convenience tool, but the gate is still the hook. This keeps enforcement mechanical and independent of whether the skill called the tool correctly.

---

## 6. Coherence Strategy

As ARCH grows across two repos (arch-protocol + arch-mcp), three mechanisms maintain consistency:

**Structural:**
- `schema/shift.ts` owns the state shape — SKILL.md references it by name, not by re-specifying fields
- `schema/conventions.ts` owns the solo marker naming — the only shared contract that can't be type-checked across the shell boundary
- `paths.ts` owns all path resolution — no tool computes `~/.arch/` paths inline

**Version compatibility:**
- `arch_version()` surfaces the MCP server version alongside the installed protocol version
- The skill can warn when they drift — no silent incompatibility
- Semantic versioning: patch bumps are safe; minor bumps add tools; major bumps may change tool contracts

**Process:**
- Both repos develop under ARCH — GATE forces scope declaration, SOLO prevents silent cross-component drift
- A SKILL.md change that affects MCP behavior goes through a task that must name both files in PULL
- The LOG trail makes cross-component changes traceable in `arch-evolve`

**What can't be enforced structurally:** behavioral thresholds (session warning at ≥ 5, SHIFT escalation at 3-in-5) live in SKILL.md as protocol intelligence. The MCP server owns the counter; the skill owns the threshold. The spec documents which layer owns which.

---

## 7. Testing Strategy

Unit tests cover each tool in isolation using a temp directory fixture (not `~/.arch/`). Integration tests cover the full SKILL.md flow against a real git repo.

**Unit test surface:**
- `arch_shift_read`: missing file → creates default; existing file with missing fields → backfills via `DEFAULT_SHIFT_STATE`
- `arch_anchor`: clean tree → `dirty: false`; dirty tree → `dirty: true` with file list
- `arch_retro_append`: `.arch/` exists → writes to project scope; absent → falls back to global
- `arch_solo_declare`: creates marker file; second call → `created: true` (idempotent)

**Integration test:** a single scenario that runs `arch_anchor` → `arch_solo_declare` → `arch_retro_append` → `arch_shift_read` → `arch_shift_write` against a temp git repo, verifying the files written match the schema.

---

## Non-Goals

- No protocol logic in the MCP server (thresholds, escalation rules, PUSHBACK responses)
- No arch-evolve integration (reads retro.md directly; doesn't need a tool)
- No network calls
- No Windows support in v1 (paths use `~` expansion; WSL is fine)
