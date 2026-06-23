# ARCH v1.9.0 — Deeper Hansei + Session Awareness

**Date:** 2026-06-23  
**Status:** Approved  
**Scope:** Two additive features to `plugins/arch-protocol/skills/arch-protocol/SKILL.md`  
**Version bump:** 1.8.1 → 1.9.0

---

## Motivation

Analysis of accumulated LOGs against Toyota Production System (TPS) principles revealed two gaps:

1. **Shallow LOG hansei.** Every entry records what failed and jumps straight to a procedural fix. The root cause chain is never explored — same mistakes recur. The one LOG that did go a level deeper (SOLO enforcement, Jun 22) directly drove a protocol fix (v1.8.1). That depth should be the default.

2. **Session overload goes undetected.** Six M/L tasks were completed in ~6 hours on Jun 19. Context decay between tasks is near-certain at that load; the protocol had no signal.

TPS mappings:
- Feature 1 → **Hansei + 5 Whys**: retrospective must reach root cause, not just symptom
- Feature 2 → **Heijunka-lite (andon cord)**: surface the overload signal; let the worker decide whether to stop the line

---

## Feature 1: Adaptive 5 Whys in LOG

### Default behavior

Every `❌` entry in LOG (M/L tasks, and S tasks with an incident) gets one mandatory follow-up line:

```markdown
- ❌ What failed: replace_all failed silently on emoji chars
  🤔 Why #1: used replace_all without verifying the exact fragment first — assumed the string was ASCII-safe
```

No new state. No new step. One line per `❌`, always.

Always use the `#N` suffix — even for a single level. This means escalation simply appends `#2`, `#3` without a format switch, reducing conditional logic in the AI's behavior.

### Escalation behavior

When SHIFT detects a pattern (same `omit:` key reaches 3 in the last 5 tasks), LOG for that task and subsequent tasks switches to a multi-level Why chain:

```markdown
- ❌ What failed: skipped GATE again [omit:skip_gate]
  🤔 Why #1: felt like the request was clear enough
  🤔 Why #2: time pressure making GATE feel like overhead
  🤔 Why #3 (root cause): no fixed template for common task types — each GATE reconstructed from scratch
```

Chain continues until a systemic or environmental cause is named (not another symptom). Drops back to single-level after 2 consecutive clean tasks on that key — same reset rule SHIFT already uses.

### S tasks

`🤔 Why: ...` is appended inline only when the LOG is non-clean (has an `❌`). Clean S LOGs stay compressed: `📝 LOG (S): no incidents · commit: ...`

### Execution order (critical)

Within the LOG step, the correct sequence is:

1. **Read `shift.json`** — determine current Why depth for each `omit:` key
2. **Write LOG** — using the appropriate depth (single or escalated)
3. **Optionally increment `session_task_count`** — only for M/L tasks (see Feature 2)
4. **Update `shift.json`** — persist omission counters and session count

SHIFT check must precede LOG write. Reading state after writing would apply escalation one task too late.

---

## Feature 2: Session Load Warning (Heijunka-lite)

### State

Add one field to `~/.arch/shift.json`:

```json
{
  "session_task_count": 0,
  "omissions": { ... },
  "last_omission_cleared": null,
  "log_count_at_last_evolve": 0
}
```

### Reset

At the **first GATE of each session** (the evolve check moment), reset `session_task_count = 0` and write back to `shift.json`.

The reset piggybacks on the same first-GATE detection the evolve check already uses (`log_count_at_last_evolve` comparison). No new detection mechanism is needed — the implementer adds the reset write alongside the existing evolve check logic.

> **Known edge case (not fixed in v1.9.0):** "First GATE of session" is detected implicitly — a new Claude Code conversation is a new session. If a conversation is resumed the next day, the counter retains yesterday's value and may trigger a false warning. No user reports of this yet; document here so it's diagnosable if it appears.

### Increment

At LOG, after writing the retrospective block: if the completed task was classified **M or L**, increment `session_task_count += 1`.

S tasks do not increment. Rationale: context decay correlates with M/L work (multi-file reads, writes, diffs). A session of S tasks does not degrade context the same way. S-only sessions should never trigger the warning. Additionally, excluding S tasks removes the perverse incentive to downsize an M to S to avoid the counter — ATOM's "when in doubt, size up" boundary rule already prevents this, but the exclusion makes the incentive moot.

### Check

At every GATE (after the evolve check / reset logic), before proceeding to verify fields:

```
if session_task_count >= 5:
  "⚠️ You've completed N M/L tasks this session. Context decay is likely.
   Continue, or stop here and start fresh next session?"
```

User decides. No hard block. PUSHBACK rules apply if user pushes back: acknowledge, name why the warning exists, proceed.

Initial threshold: **5 M/L tasks**. Tune via `arch-evolve` once real SHIFT data accumulates.

### Batch mode composition

Batch tasks share one GATE at the top of the batch. The session check fires at that GATE — once per batch, not once per task within the batch. If a second batch is started in the same session, GATE fires again and the warning appears if the threshold is met. This is the correct decision point: the user is about to commit to N more tasks, not mid-task.

---

## Files Changed

| File | Change |
|------|--------|
| `plugins/arch-protocol/skills/arch-protocol/SKILL.md` | Add `🤔 Why:` to LOG format; add SHIFT escalation logic; add session check in GATE; add session increment in LOG; update `shift.json` schema |
| `plugins/arch-protocol/.claude-plugin/plugin.json` | Version bump 1.8.1 → 1.9.0 |

---

## What Is Not Changing

- The 7-step sequence and step names are unchanged
- GATE fields (Objective, Context, Constraints) are unchanged
- ANCHOR, ATOM, PULL, SOLO, EYES logic is unchanged
- SHIFT omission vocabulary (controlled keys) is unchanged
- No new hooks, no new state files

---

## Success Criteria

- A LOG with an `❌` always includes at least one `🤔 Why:` line
- A LOG when SHIFT has detected a pattern includes a multi-level Why chain
- Clean S task LOGs remain on one line
- After 5 M/L completed tasks in a session, GATE warns before starting task 6
- S tasks never increment `session_task_count`
- The batch mode warning fires at the batch GATE, not between tasks within a batch
