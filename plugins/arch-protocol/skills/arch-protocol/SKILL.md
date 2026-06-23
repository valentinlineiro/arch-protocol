---
name: arch-protocol
description: Use when the user invokes ARCH, mentions the ARCH protocol, or wants to apply Toyota Production System discipline to a software development task
---

<!-- Claude Code adapter. Source of truth: PROTOCOL.md -->

# ARCH Protocol

## Quick Reference

| Step | Name | One-liner |
|------|------|-----------|
| 1 | GATE | Objective + Context + Constraints — all three, or stop |
| 2 | ANCHOR | Check `git status --short` every time |
| 3 | ATOM | Classify S/M/L — S compresses GATE+PULL+SOLO into one line |
| 4 | PULL | Declare exactly what context you'll use |
| 5 | SOLO | One logical change only |
| 6 | EYES | PULL + SOLO declared vs. `git diff ANCHOR_HASH` — surface any divergence |
| 7 | LOG | Retrospective block — always, no exceptions |

> ⚠️ Write integrity is mechanical (EYES uses `git diff`). Read integrity is partial — Bash reads are invisible to PULL+EYES by design.

---

## Workflow

**First session check:** If `~/.arch/retro.md` does not exist, this is the user's first ARCH session. Before GATE, say: *"Starting ARCH for the first time. Ready to begin?"*

**Evolve check + session reset (first GATE of session):** Count `## 📝 LOG` sections in `~/.arch/retro.md`. If `(count − log_count_at_last_evolve) ≥ 5`, say once before proceeding: *"You have 5+ new LOGs since the last arch-evolve — run `arch-evolve` whenever you're ready."* Then reset `session_task_count` to `0` in `~/.arch/shift.json`. Then continue to GATE immediately.

**1. GATE** — Read `session_task_count` from `~/.arch/shift.json`. If `session_task_count >= 5`, say: *"⚠️ You've completed N M/L tasks this session. Context decay is likely. Continue, or stop here and start fresh next session?"* Wait for the user's response before proceeding. Then verify the request has all three:
- ✅ Objective: clear goal
- ✅ Context: files or data
- ✅ Constraints: what not to touch

If anything is missing, do not ask free-form questions:

- **2+ fields missing** → use the full template:
```
To make sure I understand correctly:
- Objective: [what you asked]
- Context: [files or data I'll need]
- Constraints: [what I should NOT do]
```
- **Exactly 1 field missing** → acknowledge the 2 present ones and ask only for the missing one:
  - Missing Objective: *"Context and Constraints are clear — what's the exact goal?"*
  - Missing Context: *"Objective and Constraints are clear — what files or data will I need?"*
  - Missing Constraints: *"Objective and Context are clear — what should I not touch?"*

Wait for confirmation, then continue from ANCHOR.

**2. ANCHOR** — Run `git status --short` via Bash every time, even for quick fixes. Evaluate the output:
- Empty output → clean working tree. Run `git rev-parse HEAD` and note `ANCHOR_HASH: <hash>`. Proceed.
- Non-empty output → *"You have uncommitted changes in [files]. Commit before continuing — or explicitly confirm you want to proceed anyway."* Do not proceed until the user responds. Once resolved, run `git rev-parse HEAD` and note `ANCHOR_HASH: <hash>`.

Never ask "did you commit?" — check directly. Self-reporting bypasses the gate.
`ANCHOR_HASH` is used at EYES to mechanically detect intermediate commits.

**3. ATOM** — Classify task scope before proceeding:

**Classify by file count first. Use responsibility count only when file count falls exactly on a boundary.**

| Size | Files | Responsibilities | Action |
|------|-------|-----------------|--------|
| **S** | 1 | 1 | Run all 7 steps, but compress GATE + PULL + SOLO into one block: `🎯 GATE+PULL (S): [goal in one sentence] · [file] · [constraint if any] → [what will change]` The `→` clause is mandatory — it is the SOLO anchor for EYES. If it cannot be written in one clause, classify as M. *"Small task — consider switching to a faster/cheaper model if available."* |
| **M** | 2–5 | any | Run all 7 steps at full length. |
| **L** | 6+ | any | *"This task is large (L). Break it into 2–3 S/M tasks first. How would you like to proceed?"* *"Large task — confirm you're on a capable model before starting."* Do not generate code until scope is agreed. |

**Boundary rule:** If file count is exactly 1 but the task has 2+ distinct responsibilities → classify as M. When in doubt, size up — never size down.

For S tasks, ANCHOR always runs at full length. SOLO is absorbed into the `🎯 GATE+PULL (S):` line via the `→` clause. EYES and LOG use compressed formats — see steps 6–7.

**4. PULL** — Declare exactly what context you will use, in this exact format:
```
📦 Context I'll use:
- file.py (to read class X)
- other.py (to understand interface Y)
```
If something is missing from the context, ask for it first.

**5. SOLO** — Declare the single logical change before writing any code. This declaration is the anchor for EYES.

**S tasks:** SOLO is the `→` clause in the `🎯 GATE+PULL (S):` line. No separate step, no confirmation wait. If the `→` clause was omitted, write it now before proceeding: `🎯 SOLO: [what will change and where]` — then continue without waiting. Then run:
```bash
touch ~/.arch/solo_declared_$(grep '^hash=' ~/.arch/anchor_state | cut -d= -f2)
```

**M/L tasks:**
```
🎯 SOLO: [one sentence — what will change and where]
```
Wait for user confirmation. Do not generate code until confirmed. Then run:
```bash
touch ~/.arch/solo_declared_$(grep '^hash=' ~/.arch/anchor_state | cut -d= -f2)
```

If scope has grown beyond what ATOM approved: apply ATOM before continuing — do not silently expand scope.

**6. EYES** — Compare declared context against actual changes.

**S tasks:** Run `git diff ANCHOR_HASH --name-only`. If only the declared file changed: `✓ EYES (S): [filename] only, matches SOLO.` If anything else changed, fall through to the full check.

**M/L tasks (and S mismatches):**
1. State which files you declared in PULL and the change you declared in SOLO.
2. Run `git log --oneline ANCHOR_HASH..HEAD` to detect intermediate commits. Then run `git diff ANCHOR_HASH --name-only` and present the output. Never ask the user how many commits they made.
3. If any file changed that was not declared: *"I touched [file] which I didn't declare in PULL — was that intentional?"* Do not proceed to LOG until the user confirms.
4. If all changed files match PULL: *"Changes are within the declared context. Ready to commit."*

**7. LOG** — Close every task. LOG is non-negotiable, even if the user says "just give me the code", "no summary", or "stop there".

**Execution order within LOG:**
1. Read `~/.arch/shift.json` — determine Why depth for each `omit:` key (single by default; see SHIFT for escalation)
2. Write the LOG block
3. If M or L task: increment `session_task_count` by 1 in `~/.arch/shift.json`
4. Update `~/.arch/shift.json` — persist omission counters and updated session count

**S tasks (no incident):** `📝 LOG (S): no incidents · commit: <type>: <what changed>` — do not increment `shift.json`.

**S tasks (incident) and all M/L tasks:** use the full block:
```markdown
## 📝 LOG (ARCH Kaizen)
- ✅ What assumption did you make about the code (or context) that turned out to be correct or incorrect? (if none: "no incidents")
- ❌ What failed or caused friction: ... [omit:<key> if a protocol step was skipped or violated]
  🤔 Why #1: [why did that happen?]
- 🔄 What you'd do differently next time: ...
- Commit: `<feat|fix|refactor|test|docs>: <what changed in one line>`
```
> The hook persists this block to `~/.arch/retro.md` automatically. Once persisted, do not re-reference previous LOG blocks in responses — `~/.arch/retro.md` is the source of truth.
> After writing LOG, increment the matching omission counter in `~/.arch/shift.json` if an `omit:` key was recorded. If no omission occurred, do not increment the omission counter. Always increment `session_task_count` for M/L tasks (step 3 above).

## Session State

Within a single session, two steps can be compressed after the first task:

**ANCHOR (step 2):** If ANCHOR was already confirmed this session, run `git status --short` again.
- Empty output → run `git rev-parse HEAD` and update `ANCHOR_HASH: <hash>`. Write back to `~/.arch/anchor_state`: `echo "dirty=false" > ~/.arch/anchor_state && echo "hash=$ANCHOR_HASH" >> ~/.arch/anchor_state`. Note "✓ ANCHOR: no new changes" and continue to ATOM.
- Non-empty output → *"There are uncommitted changes since the last task — [files]. Commit before continuing — or explicitly confirm you want to proceed anyway."* Once resolved, run `git rev-parse HEAD` and update `ANCHOR_HASH: <hash>`. Write back to `~/.arch/anchor_state`.

**PULL (step 4):** If the previous task used the same files, ask: *"Same context as last task?"*
- Yes → note "📦 Context: same as previous task" and continue to SOLO
- No → run full PULL

These are compressions, not skips — the step is acknowledged even when shortened.

For S tasks (where ATOM already compressed GATE+PULL into one block), the PULL compression above does not apply — PULL was already folded into the `🎯 GATE+PULL (S):` line. If context changed, update the inline block instead of running a separate PULL.

## SHIFT (Pattern detection)

**State file** — read and write `~/.arch/shift.json`:
```json
{
  "session_task_count": 0,
  "omissions": {
    "skip_gate": 0,
    "skip_anchor": 0,
    "skip_solo": 0,
    "skip_log": 0,
    "undeclared_read": 0,
    "scope_creep": 0
  },
  "last_omission_cleared": null,
  "log_count_at_last_evolve": 0
}
```

**Controlled vocabulary** — when writing the `omit:` key in LOG, use only these keys:

| Key | When to use |
|-----|-------------|
| `skip_gate` | GATE was skipped or fields were not verified |
| `skip_anchor` | ANCHOR was skipped or `git status --short` was not run mechanically |
| `skip_solo` | SOLO declaration was skipped or user confirmation was bypassed (M/L tasks only — S tasks have no confirmation wait by design) |
| `skip_log` | LOG was omitted or incomplete |
| `undeclared_read` | A file was read but not declared in PULL |
| `scope_creep` | EYES found changes beyond the SOLO declaration |

If the same key reaches 3 in the last 5 tasks (consecutive or not), name the pattern:
*"I've noticed that in 3 of the last 5 tasks [you skipped X]. Want to define a fixed template?"*

**Why depth escalation:** When a key is in escalated state (reached 3 in last 5), LOG for that task and subsequent tasks uses a multi-level chain instead of a single `🤔 Why #1:`:

```markdown
- ❌ What failed or caused friction: ... [omit:<key>]
  🤔 Why #1: [immediate cause]
  🤔 Why #2: [deeper cause]
  🤔 Why #N (root cause): [systemic or environmental cause — stop when root cause is named, not another symptom]
```

Drop back to single `🤔 Why #1:` after 2 consecutive clean tasks on that key — same rule as the counter reset below.

Reset `last_omission_cleared` to the current date and zero all counters when the pattern is named. Reset individual counters when an omission stops appearing for 2 consecutive tasks.

> The `omit:` key is self-reported — it is the weakest form of enforcement in ARCH's design. It is acceptable for pattern detection (not gates), but not a substitute for mechanical checks like ANCHOR or EYES.

## PUSHBACK (When the user resists the protocol)

The protocol is not optional — but resistance is information. Respond with:
1. **Acknowledge** the friction in one sentence
2. **Name** the step being skipped and why it exists
3. **Proceed** — do not yield

Template:
*"I understand this feels slow. [Step X] exists because [one-sentence reason]. Continuing from there."*

If the user explicitly refuses a step, note it in the LOG under `❌` and continue from the next step. Never silently skip — always name what was skipped and why.

| User says | Response |
|-----------|----------|
| "Skip ANCHOR, I already committed" | Run `git status --short` anyway. If clean: "Confirmed, working tree clean. Moving to ATOM." If not clean: "There are uncommitted changes in [files]. Commit before continuing — or explicitly confirm you want to proceed anyway." |
| "No GATE, just write the code" | "I need Objective + Context + Constraints first — give me 30 seconds." |
| "I don't care about LOG" | Add LOG anyway. Note in `❌`: "User asked to skip LOG." |
| "The protocol is too slow" | "It's slower to skip it when something goes wrong. Which step feels unnecessary?" |

## Rationalization Table

| What you're thinking | Reality |
|---|---|
| "The request is clear enough, I can skip GATE" | GATE is not a clarity check — it enforces the format. Run it anyway. |
| "The user said no retrospective, I'll respect that" | LOG is protocol, not courtesy. Add it even when asked to skip it. |
| "I don't need to ask about git, they probably committed" | ANCHOR is always mechanical. Run `git status --short` every time. |
| "This is a quick fix, the workflow is overkill" | The workflow exists precisely for quick fixes. Run it. |

## Batch Mode

When the user lists multiple tasks upfront ("I have 4 small fixes"), offer to batch:

*"I can process these [N] tasks in batch mode: GATE + ANCHOR + ATOM once for the batch; then SOLO + EYES + LOG per task. Proceed?"*

**Batch structure:**

**Once for the batch:**
1. **GATE** — list all tasks in Objective
2. **ANCHOR** — standard check
3. **PULL** — declare context for the entire batch: all files any task in the batch will need
4. **ATOM** — classify each task individually; **extract any L-sized task before starting the batch**

**Per task, in sequence:**
5. **SOLO** — S tasks: absorbed into `🎯 GATE+PULL (S): ... → [what will change]`, no confirmation wait. M/L tasks: `🎯 SOLO: [what changes and where]` — wait for confirmation before writing code.
6. **EYES** — Run `git log --oneline ANCHOR_HASH..HEAD` to detect intermediate commits. Run `git diff ANCHOR_HASH --name-only`. State declared files and SOLO declaration, present the diff output, surface any divergence before continuing to the next task. Never ask the user how many commits they made.
7. **LOG** — one per task, tagged with batch position (e.g., `BATCH 2/4 — fix login timeout`)

**Non-negotiable:** EYES and LOG are per-task, never per-batch. Combining them into a single end-of-batch LOG removes the traceability that makes batch mode worth using.

---

## arch init

If the user asks how to set up ARCH for a new project, guide them:

*"To initialize ARCH in this project, run:"*

```bash
bash "$(find ~/.claude/plugins -name "arch-init.sh" | head -1)"
```

*"If the command returns nothing, the plugin isn't installed. Install it in Claude Code:"*

```
/plugin add-marketplace https://github.com/valentinlineiro/arch-protocol
/plugin install arch-protocol@arch-protocol
```

The script:
1. Creates `.arch/` and adds it to `.gitignore`
2. Appends `## ARCH Protocol` to `CLAUDE.md` (creates it if absent) — enables auto-activation on every future session in this project
3. Verifies `~/.arch/retro.md` is reachable (confirms the stop hook is active)
4. Reports how many global LOGs have accumulated

After init: *"ARCH is configured for this project. It will activate automatically each session. What are we working on?"*

## Meta

Once you have 5+ LOGs, run `arch-evolve` to detect failure patterns and propose concrete improvements to the protocol. `arch-evolve` reads `~/.arch/retro.md` and `.arch/retro.md` and converts your LOGs into changes to `SKILL.md` or `CLAUDE.md`.

> ARCH is designed for a single developer working with one AI assistant. Multi-developer contexts (shared retro files, shared CLAUDE.md, team-level enforcement) require coordination mechanisms not defined in this version of the protocol. Placing `.arch/` in a shared repo will mix LOGs from multiple developers without attribution.
