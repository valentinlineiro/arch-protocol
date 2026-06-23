# arch-mcp npm publish + SKILL.md wiring Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Publish `@valentinlineiro/arch-mcp@1.0.0` to npm, wire it into arch-protocol's plugin manifest, and replace all raw Bash state operations in SKILL.md with MCP tool calls.

**Architecture:** Two sequential repo changes — arch-mcp gets a GitHub remote and npm publish; arch-protocol gains an `mcpServers` declaration in plugin.json and a rewritten SKILL.md that calls MCP tools instead of raw Bash. The MCP server is a hard dependency: no Bash fallbacks.

**Tech Stack:** Node.js / TypeScript, npm, Claude Code plugin system, MCP SDK

## Global Constraints

- arch-mcp version target: `1.0.0`
- arch-protocol version target: `2.0.0`
- npm package name: `@valentinlineiro/arch-mcp`
- GitHub org/user: `valentinlineiro`
- MCP server name in plugin: `arch-mcp`
- Tool naming convention: `mcp__arch-mcp__<tool_name>`
- Hard dependency: SKILL.md must never read `~/.arch/*` files directly — always call MCP tools and use returned values
- plugin.json field: `mcpServers` (object keyed by name, per Claude Code plugin reference)
- Exact version pin in args: `@valentinlineiro/arch-mcp@1.0.0`

---

## File Map

**arch-mcp repo** (`/home/valentin/code/arch-mcp`):
- Modify: `package.json` — version 0.1.0 → 1.0.0
- Modify: `src/index.ts` — McpServer version string 0.1.0 → 1.0.0
- Rebuild: `dist/index.js` (via `npm run build`)

**arch-protocol repo** (`/home/valentin/code/arch-protocol`):
- Modify: `plugins/arch-protocol/.claude-plugin/plugin.json` — add `mcpServers`, bump version to 2.0.0
- Modify: `plugins/arch-protocol/skills/arch-protocol/SKILL.md` — 9 targeted text replacements (see Task 3)

---

## MCP Tool Call Reference

All tools return `{ success: true, data: <payload> }` on success.

| Tool | Parameters | Returns |
|------|-----------|---------|
| `mcp__arch-mcp__arch_anchor` | none | `{ dirty: bool, hash: string, uncommitted_files: string[] }` |
| `mcp__arch-mcp__arch_solo_declare` | `{ hash: string }` | `{ marker_path: string, created: true }` |
| `mcp__arch-mcp__arch_shift_read` | none | full `ShiftState` object |
| `mcp__arch-mcp__arch_shift_write` | `{ state: ShiftState }` | `{ written: true }` |
| `mcp__arch-mcp__arch_session_increment` | none | `{ session_task_count: number }` |
| `mcp__arch-mcp__arch_version` | none | `{ mcp_version: string, protocol_version: string }` |

`ShiftState` schema:
```json
{
  "session_task_count": 0,
  "omissions": {
    "skip_gate": 0, "skip_anchor": 0, "skip_solo": 0,
    "skip_log": 0, "undeclared_read": 0, "scope_creep": 0
  },
  "last_omission_cleared": null,
  "log_count_at_last_evolve": 0
}
```

---

### Task 1: Publish arch-mcp 1.0.0 to npm

**Files:**
- Modify: `/home/valentin/code/arch-mcp/package.json`
- Modify: `/home/valentin/code/arch-mcp/src/index.ts`
- Rebuild: `/home/valentin/code/arch-mcp/dist/` (via build)

**Interfaces:**
- Produces: `@valentinlineiro/arch-mcp@1.0.0` on npm; GitHub remote `valentinlineiro/arch-mcp`

- [ ] **Step 1: Create GitHub repo**

Go to https://github.com/new — create `valentinlineiro/arch-mcp` (public, no README/gitignore, empty). This step requires browser access and cannot be automated.

- [ ] **Step 2: Bump version in package.json**

In `/home/valentin/code/arch-mcp/package.json`, change:
```json
"version": "0.1.0",
```
to:
```json
"version": "1.0.0",
```

- [ ] **Step 3: Bump McpServer version in src/index.ts**

In `/home/valentin/code/arch-mcp/src/index.ts`, change:
```ts
const server = new McpServer({ name: 'arch-mcp', version: '0.1.0' });
```
to:
```ts
const server = new McpServer({ name: 'arch-mcp', version: '1.0.0' });
```

- [ ] **Step 4: Rebuild**

```bash
cd /home/valentin/code/arch-mcp && npm run build
```
Expected: exits 0, no TypeScript errors.

- [ ] **Step 5: Verify version tool returns 1.0.0**

```bash
node -e "import('/home/valentin/code/arch-mcp/dist/tools/version.js').then(m => m.runVersion()).then(r => console.log(JSON.stringify(r)));"
```
Expected: `{"mcp_version":"1.0.0","protocol_version":"1.9.2"}` (protocol_version updates after Task 2 ships)

- [ ] **Step 6: Commit**

```bash
git -C /home/valentin/code/arch-mcp add package.json src/index.ts dist/
git -C /home/valentin/code/arch-mcp commit -m "chore: bump version to 1.0.0 for npm publish"
```

- [ ] **Step 7: Add remote and push**

```bash
git -C /home/valentin/code/arch-mcp remote add origin https://github.com/valentinlineiro/arch-mcp.git
git -C /home/valentin/code/arch-mcp push -u origin main
```
Expected: branch `main` tracked on remote.

- [ ] **Step 8: Check npm login**

```bash
npm whoami
```
If not logged in: `npm login` (interactive — requires browser or OTP).

- [ ] **Step 9: Publish to npm**

```bash
cd /home/valentin/code/arch-mcp && npm publish --access public
```
Expected output includes `+ @valentinlineiro/arch-mcp@1.0.0`.

- [ ] **Step 10: Verify on npm**

```bash
npm view @valentinlineiro/arch-mcp version
```
Expected: `1.0.0`

---

### Task 2: plugin.json — mcpServers + version 2.0.0

**Files:**
- Modify: `/home/valentin/code/arch-protocol/plugins/arch-protocol/.claude-plugin/plugin.json`

**Interfaces:**
- Consumes: `@valentinlineiro/arch-mcp@1.0.0` (must be on npm before this ships)
- Produces: plugin manifest that auto-starts arch-mcp via npx on plugin load

- [ ] **Step 1: Update plugin.json**

Replace the full content of `/home/valentin/code/arch-protocol/plugins/arch-protocol/.claude-plugin/plugin.json` with:
```json
{
  "name": "arch-protocol",
  "version": "2.0.0",
  "description": "ARCH protocol skill — structured human+AI software development based on Toyota Production System principles. Enforces atomic tasks, pre-flight validation, context declaration, and kaizen retrospectives.",
  "author": {
    "name": "Valentín Liñeiro"
  },
  "homepage": "https://github.com/valentinlineiro/arch-protocol",
  "mcpServers": {
    "arch-mcp": {
      "command": "npx",
      "args": ["-y", "@valentinlineiro/arch-mcp@1.0.0"]
    }
  }
}
```

- [ ] **Step 2: Commit**

```bash
git -C /home/valentin/code/arch-protocol add plugins/arch-protocol/.claude-plugin/plugin.json
git -C /home/valentin/code/arch-protocol commit -m "feat: add mcpServers to plugin.json, bump to 2.0.0"
```

---

### Task 3: Wire SKILL.md — 9 targeted replacements

**Files:**
- Modify: `/home/valentin/code/arch-protocol/plugins/arch-protocol/skills/arch-protocol/SKILL.md`

**Interfaces:**
- Consumes: MCP tool reference table (tool names and return shapes defined above)
- Produces: SKILL.md with all Bash state operations replaced by MCP tool calls; no direct file reads of `~/.arch/*`

Apply each replacement in order. Read the file before the first edit.

- [ ] **Step 1: Change 1 — Evolve check: add arch_version + wire session reset**

Find:
```
**Evolve check + session reset (first GATE of session):** Count `## 📝 LOG` sections in `~/.arch/retro.md`. If `(count − log_count_at_last_evolve) ≥ 5`, say once before proceeding: *"You have 5+ new LOGs since the last arch-evolve — run `arch-evolve` whenever you're ready."* Then reset `session_task_count` to `0` in `~/.arch/shift.json`. Then continue to GATE immediately.
```

Replace with:
```
**Evolve check + session reset (first GATE of session):** Call `mcp__arch-mcp__arch_version` — note the returned `protocol_version`. Call `mcp__arch-mcp__arch_shift_read` — note the returned `log_count_at_last_evolve`. Count `## 📝 LOG` sections in `~/.arch/retro.md` via Bash. If `(count − log_count_at_last_evolve) ≥ 5`, say once before proceeding: *"ARCH Protocol v[protocol_version] — You have 5+ new LOGs since the last arch-evolve — run `arch-evolve` whenever you're ready."* Then call `mcp__arch-mcp__arch_shift_write` with the state received from `arch_shift_read` updated so `session_task_count` is `0`. Then continue to GATE immediately.
```

- [ ] **Step 2: Change 2 — GATE: wire arch_shift_read for session_task_count**

Find:
```
**1. GATE** — Read `session_task_count` from `~/.arch/shift.json`. If `session_task_count >= 5`, say: *"⚠️ You've completed N M/L tasks this session.
```

Replace with:
```
**1. GATE** — Call `mcp__arch-mcp__arch_shift_read` and use the returned `session_task_count`. If `session_task_count >= 5`, say: *"⚠️ You've completed N M/L tasks this session.
```

- [ ] **Step 3: Change 3 — ANCHOR: replace Bash with arch_anchor**

Find:
```
**2. ANCHOR** — Run `git status --short` via Bash every time, even for quick fixes. Evaluate the output:
- Empty output → clean working tree. Run `git rev-parse HEAD` and note `ANCHOR_HASH: <hash>`. Proceed.
- Non-empty output → *"You have uncommitted changes in [files]. Commit before continuing — or explicitly confirm you want to proceed anyway."* Do not proceed until the user responds. Once resolved, run `git rev-parse HEAD` and note `ANCHOR_HASH: <hash>`.

Never ask "did you commit?" — check directly. Self-reporting bypasses the gate.
`ANCHOR_HASH` is used at EYES to mechanically detect intermediate commits.
```

Replace with:
```
**2. ANCHOR** — Call `mcp__arch-mcp__arch_anchor`. It runs `git status --short` and `git rev-parse HEAD`, writes anchor state, and returns `{ dirty, hash, uncommitted_files }`. Evaluate the result:
- `dirty: false` → clean working tree. Note `ANCHOR_HASH: <hash>`. Proceed.
- `dirty: true` → *"You have uncommitted changes in [uncommitted_files]. Commit before continuing — or explicitly confirm you want to proceed anyway."* Do not proceed until the user responds. Once resolved, call `mcp__arch-mcp__arch_anchor` again and note the new `ANCHOR_HASH`.

Never ask "did you commit?" — check directly. Self-reporting bypasses the gate.
`ANCHOR_HASH` is used at EYES to mechanically detect intermediate commits.
```

- [ ] **Step 4: Change 4 — SOLO (S tasks): replace Bash touch with arch_solo_declare**

Find:
```
**S tasks:** SOLO is the `→` clause in the `🎯 GATE+PULL (S):` line. No separate step, no confirmation wait. If the `→` clause was omitted, write it now before proceeding: `🎯 SOLO: [what will change and where]` — then continue without waiting. Then run:
```bash
touch ~/.arch/solo_declared_$(grep '^hash=' ~/.arch/anchor_state | cut -d= -f2)
```
```

Replace with:
```
**S tasks:** SOLO is the `→` clause in the `🎯 GATE+PULL (S):` line. No separate step, no confirmation wait. If the `→` clause was omitted, write it now before proceeding: `🎯 SOLO: [what will change and where]` — then continue without waiting. Then call `mcp__arch-mcp__arch_solo_declare` with `{ "hash": "<ANCHOR_HASH>" }`.
```

- [ ] **Step 5: Change 5 — SOLO (M/L tasks): replace Bash touch with arch_solo_declare**

Find:
```
Wait for user confirmation. Do not generate code until confirmed. Then run:
```bash
touch ~/.arch/solo_declared_$(grep '^hash=' ~/.arch/anchor_state | cut -d= -f2)
```

If scope has grown beyond what ATOM approved
```

Replace with:
```
Wait for user confirmation. Do not generate code until confirmed. Then call `mcp__arch-mcp__arch_solo_declare` with `{ "hash": "<ANCHOR_HASH>" }`.

If scope has grown beyond what ATOM approved
```

- [ ] **Step 6: Change 6 — LOG execution order: wire all three MCP calls**

Find:
```
**Execution order within LOG:**
1. Read `~/.arch/shift.json` — determine Why depth for each `omit:` key (single by default; see SHIFT for escalation)
2. Write the LOG block
3. If M or L task: increment `session_task_count` by 1 in `~/.arch/shift.json`
4. Update `~/.arch/shift.json` — persist omission counters and updated session count
```

Replace with:
```
**Execution order within LOG:**
1. Call `mcp__arch-mcp__arch_shift_read` — use the returned state to determine Why depth for each `omit:` key (single by default; see SHIFT for escalation)
2. Write the LOG block
3. If M or L task: call `mcp__arch-mcp__arch_session_increment`
4. If any `omit:` key was recorded: call `mcp__arch-mcp__arch_shift_write` with the state from step 1, incrementing the matching omission counter by 1
```

- [ ] **Step 7: Change 7 — LOG footnote: replace file-write references**

Find:
```
> After writing LOG, increment the matching omission counter in `~/.arch/shift.json` if an `omit:` key was recorded. If no omission occurred, do not increment the omission counter. Always increment `session_task_count` for M/L tasks (step 3 above).
```

Replace with:
```
> After writing LOG, call `mcp__arch-mcp__arch_shift_write` with the incremented omission counter if an `omit:` key was recorded. If no omission occurred, do not call `arch_shift_write`. Always call `mcp__arch-mcp__arch_session_increment` for M/L tasks (step 3 above).
```

- [ ] **Step 8: Change 8 — Session State ANCHOR compression: wire arch_anchor**

Find:
```
**ANCHOR (step 2):** If ANCHOR was already confirmed this session, run `git status --short` again.
- Empty output → run `git rev-parse HEAD` and update `ANCHOR_HASH: <hash>`. Write back to `~/.arch/anchor_state`: `echo "dirty=false" > ~/.arch/anchor_state && echo "hash=$ANCHOR_HASH" >> ~/.arch/anchor_state`. Note "✓ ANCHOR: no new changes" and continue to ATOM.
- Non-empty output → *"There are uncommitted changes since the last task — [files]. Commit before continuing — or explicitly confirm you want to proceed anyway."* Once resolved, run `git rev-parse HEAD` and update `ANCHOR_HASH: <hash>`. Write back to `~/.arch/anchor_state`.
```

Replace with:
```
**ANCHOR (step 2):** If ANCHOR was already confirmed this session, call `mcp__arch-mcp__arch_anchor` again.
- `dirty: false` → update `ANCHOR_HASH` to the returned `hash`. Note "✓ ANCHOR: no new changes" and continue to ATOM.
- `dirty: true` → *"There are uncommitted changes since the last task — [uncommitted_files]. Commit before continuing — or explicitly confirm you want to proceed anyway."* Once resolved, call `mcp__arch-mcp__arch_anchor` again and update `ANCHOR_HASH` to the returned `hash`.
```

- [ ] **Step 9: Change 9 — SHIFT state file: mark as MCP-managed**

Find:
```
**State file** — read and write `~/.arch/shift.json`:
```

Replace with:
```
**State file** — managed exclusively via MCP tools; do not read or write `~/.arch/shift.json` directly. Schema reference:
```

- [ ] **Step 10: Verify the diff is clean**

```bash
grep -n "shift\.json\|touch ~/.arch\|anchor_state\|rev-parse HEAD\|git status --short" \
  /home/valentin/code/arch-protocol/plugins/arch-protocol/skills/arch-protocol/SKILL.md
```

Expected: zero matches for imperative Bash commands. The only hits should be inside the Rationalization Table ("ANCHOR is always mechanical. Run `git status --short` every time.") and the EYES section (which uses `git diff` and `git log`, not state writes — those stay as Bash).

- [ ] **Step 11: Commit**

```bash
git -C /home/valentin/code/arch-protocol add plugins/arch-protocol/skills/arch-protocol/SKILL.md
git -C /home/valentin/code/arch-protocol commit -m "feat: wire SKILL.md to use MCP tools for all state operations"
```

---

### Task 4: Push arch-protocol 2.0.0, reinstall, end-to-end test

**Files:** none (verification only)

**Interfaces:**
- Consumes: arch-protocol 2.0.0 commits from Tasks 2–3; `@valentinlineiro/arch-mcp@1.0.0` on npm

- [ ] **Step 1: Push arch-protocol**

```bash
git -C /home/valentin/code/arch-protocol push origin main
```

- [ ] **Step 2: Update plugin in Claude Code**

In Claude Code terminal:
```
/plugin
/reload-plugins
```
Expected: `/plugin` shows "Updated arch-protocol"; `/reload-plugins` shows MCP server active.

- [ ] **Step 3: Verify arch_version returns correct versions**

Call `mcp__arch-mcp__arch_version` (no parameters).

Expected:
```json
{ "success": true, "data": { "mcp_version": "1.0.0", "protocol_version": "2.0.0" } }
```

- [ ] **Step 4: Test ANCHOR — arch_anchor called, no separate Bash**

Start a new ARCH task. At ANCHOR step, verify Claude calls `mcp__arch-mcp__arch_anchor` — not raw `git status --short` + `git rev-parse HEAD` + file echo separately. Confirm returned `hash` is noted as `ANCHOR_HASH`.

- [ ] **Step 5: Test SOLO — arch_solo_declare called with ANCHOR_HASH**

Declare SOLO (any task size). Verify Claude calls `mcp__arch-mcp__arch_solo_declare` with `{ "hash": "<ANCHOR_HASH>" }` — not `touch ~/.arch/solo_declared_*`.

- [ ] **Step 6: Test arch_shift_read in isolation**

Call `mcp__arch-mcp__arch_shift_read` directly. Verify it returns a valid `ShiftState` with `session_task_count`, all omission keys, `log_count_at_last_evolve`, `last_omission_cleared`.

- [ ] **Step 7: Test GATE context-decay with session_task_count >= 5**

Set `session_task_count` to 5 via `mcp__arch-mcp__arch_shift_write`:
```json
{
  "state": {
    "session_task_count": 5,
    "omissions": { "skip_gate": 0, "skip_anchor": 0, "skip_solo": 0, "skip_log": 0, "undeclared_read": 0, "scope_creep": 0 },
    "last_omission_cleared": null,
    "log_count_at_last_evolve": 0
  }
}
```

Start a new ARCH task and run GATE. Verify Claude warns: *"⚠️ You've completed 5 M/L tasks this session. Context decay is likely..."*

Reset afterward: call `mcp__arch-mcp__arch_shift_write` with `session_task_count: 0`.

- [ ] **Step 8: Test LOG omission counter (arch_shift_write)**

Complete an M task. In LOG, record an `omit:` key (e.g., `[omit:skip_gate]`). Verify Claude calls `mcp__arch-mcp__arch_shift_write` with `skip_gate` incremented by 1.

Confirm: call `mcp__arch-mcp__arch_shift_read` — `omissions.skip_gate` should be 1.

- [ ] **Step 9: Test LOG M/L session count (arch_session_increment)**

Complete an M task with no `omit:` key. Verify Claude calls `mcp__arch-mcp__arch_session_increment` at LOG step 3.

Confirm: call `mcp__arch-mcp__arch_shift_read` — `session_task_count` should be incremented.
