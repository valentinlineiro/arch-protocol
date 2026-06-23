# ARCH v2.1.0 — FEED Step: LOG→GATE Feedback Loop

**Date:** 2026-06-23
**Status:** Approved
**Scope:** Add FEED as step 1, renumber to 8-step protocol, new `arch_feed_read` MCP tool, `on-stop.sh` Ghost Constraint fix
**Version bumps:** arch-mcp `1.0.0` → `1.1.0`, arch-protocol plugin `2.0.1` → `2.1.0`

---

## Motivation

ARCH's 7-step workflow is linear: each task starts fresh from GATE with no structured memory of what just failed. The `🔄` (What you'd do differently) and `✅` (assumption correctness) fields in LOG are forward-looking by design — they describe the next task's constraints and calibrated priors — but nothing mechanically carries them there. Under pressure or context decay, they are silently ignored.

This is the missing PDCA bridge: LOG = Check/Act; FEED = carry Act forward into Plan (GATE). Without FEED, each task is an isolated Deming loop with no outer improvement spiral.

**Why a numbered step (not a preamble):** In ARCH, only numbered steps are tracked, enforced, and audited via `shift.json` omission keys. An unnumbered FEED would bypass mechanical accountability and be skipped under user pressure. First-class citizenship is the cost of enforcement.

---

## Section 1: Overview & Step Table

The sequence shifts from 7 to 8 steps. FEED becomes step 1; all existing steps shift +1:

| Step | Name | One-liner |
|------|------|-----------|
| **1** | **FEED** | Surface calibrated priors + constraints from the last LOG — or skip cleanly |
| 2 | GATE | Objective + Context + Constraints — all three, or stop |
| 3 | ANCHOR | Check git status every time |
| 4 | ATOM | Classify S/M/L |
| 5 | PULL | Declare exactly what context you'll use |
| 6 | SOLO | One logical change only |
| 7 | EYES | PULL + SOLO declared vs. `git diff ANCHOR_HASH` |
| 8 | LOG | Retrospective block — always, no exceptions |

FEED fires before every task, including the first task of a new session. Cold-start (returning after a break) is precisely when context decay is highest and constraints are most likely to be forgotten.

---

## Section 2: FEED Step Behavior

### Trigger

FEED fires before every task. It calls `arch_feed_read` (MCP tool) and branches on `has_feed`.

### Full path — `has_feed: true`

Call `mcp__plugin_arch-protocol_arch-mcp__arch_feed_read` with `{ "project_path": "<cwd>" }`. Surface:

```
🔄 FEED: Carry-forward from previous task (commit: <last_commit>)
- 💡 Calibrated Prior: <calibrated_prior>
- 🎯 Constraint: <constraint>
```

The carried constraint is **prepended to the Constraints field in GATE**. The user sees it explicitly and may accept, override, or extend it. If they override, note the override in GATE — do not silently drop it.

### Clean path — `has_feed: false`

```
✓ FEED: no constraints carried forward.
```

Continue to GATE immediately.

### S-task compression

If the initial task assessment indicates S *and* `has_feed: false`:

```
✓ FEED (S): no constraints carried forward.
```

If `has_feed: true`, FEED always runs at full length regardless of task size. A carried constraint does not compress.

> The S/M/L classification at FEED relies on the same implicit pre-ATOM assessment already used for GATE+PULL(S) compression. No new behavior required.

### Constraint lifecycle

A constraint carried into GATE is considered **resolved** when the task's LOG has no `❌` entry touching the same area (clean LOG or different failure mode).

If the same friction reappears in LOG, the constraint carries forward again *and* triggers Why escalation in LOG scoped to that specific failure mode. Escalation follows the same depth rules as SHIFT omission escalation.

### SHIFT omission key

`skip_feed` is added to the controlled vocabulary. Used when FEED was skipped or `arch_feed_read` was not called. Same pattern-detection rules as other keys (3 in last 5 → name the pattern).

`shift.json` schema update:
```json
{
  "omissions": {
    "skip_feed": 0,
    "skip_gate": 0,
    "skip_anchor": 0,
    "skip_solo": 0,
    "skip_log": 0,
    "undeclared_read": 0,
    "scope_creep": 0
  }
}
```

---

## Section 3: Session Sequencing

### Session start (once per session, before the first task)

1. **First session check** — if `~/.arch/retro.md` does not exist, greet first-time user
2. **Evolve check + session reset** — call `arch_version` + `arch_shift_read`, count LOGs, fire evolve nudge if ≥5, reset `session_task_count` to 0

### Per task (every task, including the first)

FEED (1) → GATE (2) → ANCHOR (3) → ATOM (4) → PULL (5) → SOLO (6) → EYES (7) → LOG (8)

The evolve check remains a session-level preamble. It counts all LOGs across projects. FEED reads the last project-scoped LOG. They are independent and do not interfere.

---

## Section 4: `arch_feed_read` MCP Tool

**Location:** `arch-mcp` repo, `src/tools/feed.ts`
**Registered as:** `arch_feed_read` in `src/index.ts`
**SKILL.md call site:** `mcp__plugin_arch-protocol_arch-mcp__arch_feed_read`

### Signature

```ts
arch_feed_read({ project_path?: string }) → FeedResult
```

`project_path` defaults to `process.cwd()` when omitted.

### Return type

```ts
type FeedResult =
  | { has_feed: false }
  | {
      has_feed: true;
      last_commit: string;       // commit line from LOG ("feat: ..." or "fix: ...")
      calibrated_prior: string;  // ✅ field text
      constraint: string;        // 🔄 field text
    }
```

### Resolution logic (priority order)

1. **Local retro first:** If `./.arch/retro.md` exists → read the last `## 📝 LOG` entry (or `📝 LOG (S):` line) from that file. Extract `✅` and `🔄` fields. Apply clean-check (see below).
2. **Global with project matching:** If only `~/.arch/retro.md` exists → read backward, find the last LOG entry whose metadata comment (`<!-- ARCH LOG | <timestamp> | <path> -->`) matches `project_path` (prefix match). Apply same clean-check.
3. **No match:** Return `{ has_feed: false }`.

### Clean-check

Return `{ has_feed: false }` when the last matching LOG entry is any of:
- A `📝 LOG (S): no incidents` line
- A full block where both `❌` and `🔄` fields are "no incidents" (or equivalent)
- `✅` field is "no incidents" AND no `❌` entry exists

### Edge cases (all return `{ has_feed: false }`, never throw)

| Condition | Behavior |
|---|---|
| File doesn't exist | `{ has_feed: false }` |
| File exists, no LOG entries | `{ has_feed: false }` |
| Last LOG is `📝 LOG (S): no incidents` | `{ has_feed: false }` |
| `✅` or `🔄` field is "no incidents" | `{ has_feed: false }` |
| Malformed/unparseable entry | `{ has_feed: false }` |
| Last global LOG is from a different project | `{ has_feed: false }` |

---

## Section 5: `on-stop.sh` Fix — Ghost Constraint Bug

### The bug

`on-stop.sh` matches only `## 📝 LOG (ARCH Kaizen)` blocks. Clean S-task LOGs (`📝 LOG (S): no incidents · commit: ...`) do not match and are **never written to `retro.md`**.

**Ghost Constraint loop:**
1. Task 1 (M): fails, writes `## 📝 LOG (ARCH Kaizen)` with a constraint to `retro.md`
2. Task 2 (S): runs clean, FEED carries Task 1's constraint, Task 2 finishes with `📝 LOG (S): no incidents` — nothing written to `retro.md`
3. Task 3 (M): FEED reads `retro.md`, last entry is still Task 1's incident → constraint carried forward indefinitely

### The fix

Update `on-stop.sh` to also capture and append clean S-task LOG lines.

**Format appended to retro.md for clean S-task:**
```
<!-- ARCH LOG | <timestamp> | <project_path> -->
📝 LOG (S): no incidents · commit: fix: update test markers
```

`arch_feed_read` resolution: a last entry matching `📝 LOG (S): no incidents` returns `{ has_feed: false }`, clearing the constraint.

---

## Section 6: PROTOCOL.md & SKILL.md Relationship

PROTOCOL.md is the **platform-agnostic specification** — the portability baseline for future ports to Cursor, Aider, Copilot, and other tools that do not use Claude Code's MCP namespacing.

SKILL.md is the **Claude Code adapter** — it implements the abstract protocol using MCP tool calls.

### Comment fix in SKILL.md

Change:
```
<!-- Claude Code adapter. Source of truth: PROTOCOL.md -->
```
To:
```
<!-- Claude Code adapter. Adapted from platform-agnostic specification in PROTOCOL.md -->
```

### Both files updated

PROTOCOL.md carries the abstract FEED step (no MCP tool names, uses generic `TOOL: arch_feed_read` notation). SKILL.md carries the MCP-specific implementation. Both are updated with step renumbering (1→8) and `skip_feed` in the SHIFT vocabulary.

---

## Artifact Scope

| Artifact | Change |
|---|---|
| `arch-mcp/src/tools/feed.ts` | New `arch_feed_read` tool (create) |
| `arch-mcp/src/index.ts` | Register `arch_feed_read` |
| `arch-mcp/package.json` | `1.0.0` → `1.1.0` |
| `plugins/arch-protocol/PROTOCOL.md` | Add FEED step (abstract), renumber 1→8, add `skip_feed` |
| `plugins/arch-protocol/skills/arch-protocol/SKILL.md` | Fix adapter comment, add FEED step (MCP), renumber 1→8, add `skip_feed` |
| `plugins/arch-protocol/.claude-plugin/plugin.json` | Pin `@valentinlineiro/arch-mcp@1.1.0`, version `2.0.1` → `2.1.0` |
| `plugins/arch-protocol/scripts/on-stop.sh` | Capture clean S-task LOG lines |
| `tests/feed-carry-forward.md` | New scenario: constraint carries forward from M task incident |
| `tests/feed-ghost-constraint.md` | New scenario: clean S-task clears constraint (Ghost Constraint regression) |
