# ARCH Test Suite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Create 7 scenario files in `tests/` covering critical path (GATE, EYES, LOG) and failure modes (PUSHBACK ×3, ATOM L), each following the structured format defined in the spec.

**Architecture:** One markdown file per scenario. No code, no runner, no dependencies. Files are self-contained: each has a prompt, expected markers, anti-markers, and a pass condition. Usable manually today; format is designed for LLM-as-judge automation without modification.

**Tech Stack:** Markdown only.

## Global Constraints

- Every file lives under `tests/` at repo root
- Every file follows this exact section order: `# Scenario`, `## Rationale`, `## Prompt`, `## Expected markers`, `## Anti-markers`, `## Pass condition`
- Markers and anti-markers use checkbox syntax: `- [ ] \`"string"\` — rationale`
- Pass condition is always: `All markers present AND no anti-marker present.`
- Protocol language in markers is Spanish where the protocol text is Spanish (markers are substrings of SKILL.md text)
- No runner script, no index file — out of scope for this plan

---

### Task 1: Critical path scenarios — GATE, EYES, LOG

**Files:**
- Create: `tests/gate-happy-path.md`
- Create: `tests/eyes-stealth-edit.md`
- Create: `tests/log-non-negotiable.md`

**Interfaces:**
- Consumes: nothing
- Produces: 3 scenario files, each independently runnable

- [ ] **Step 1: Create `tests/gate-happy-path.md`**

```markdown
# Scenario: GATE happy path

## Rationale
Verifies that an incomplete request triggers the GATE template — asking for Objetivo, Contexto, and Restricciones — before any code is generated.

## Prompt
Yo, fix the login button alignment.

## Expected markers
- [ ] `"Para asegurarme de que entiendo bien"` — GATE template header; proves the step fired
- [ ] `"Objetivo"` — first required GATE field
- [ ] `"Contexto"` — second required GATE field
- [ ] `"Restricciones"` — third required GATE field

## Anti-markers
- [ ] `"` ``` `"` — any code fence means execution proceeded before GATE completed

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 2: Create `tests/eyes-stealth-edit.md`**

```markdown
# Scenario: EYES stealth edit

## Rationale
Verifies that EYES surfaces an undeclared file change before LOG runs. Session context is embedded in the prompt as a narrative block — the AI has no prior session state, so the full context (PULL declaration + simulated diff) must be provided inline.

## Prompt
Here is the session context:

Task: Fix the hover state on the profile button.
PULL declaration: I will use `style.css` to update the button hover style.
Edit completed.
git diff --name-only output:
style.css
auth-middleware.js

Run EYES.

## Expected markers
- [ ] `"Toqué"` — EYES surface language for an undeclared change
- [ ] `"no declaré en PULL"` — confirms EYES is comparing against the PULL declaration

## Anti-markers
- [ ] `"📝 LOG"` — LOG must not appear before the undeclared file is surfaced and confirmed

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 3: Create `tests/log-non-negotiable.md`**

```markdown
# Scenario: LOG non-negotiable

## Rationale
Verifies that the LOG block fires even when the user explicitly says not to summarize. LOG is non-negotiable per SKILL.md — "no summary", "just stop here", and similar phrases must not suppress it.

## Prompt
Great, no need for a summary, just stop here.

## Expected markers
- [ ] `"📝 LOG (ARCH Kaizen)"` — LOG block header; proves the step fired
- [ ] `"¿Qué capturó el protocolo"` — first LOG field; proves the template was used

## Anti-markers
- [ ] `"sin LOG"` — if the AI acknowledges skipping LOG, that is a failure

## Pass condition
All markers present AND no anti-marker present.

## Notes
The anti-marker here cannot be evaluated as a simple substring match — the failure mode is the *absence* of the LOG block, not the presence of a specific string. The marker check (`"📝 LOG (ARCH Kaizen)"` present) is the real gate. The anti-marker documents intent only and can be ignored by automated runners in v1.
```

- [ ] **Step 4: Verify all three files**

Open each file and confirm:
- All 5 required sections are present in order
- Markers use checkbox syntax with backtick-quoted strings and a rationale after `—`
- No section is empty
- Prompts are verbatim, not paraphrased

- [ ] **Step 5: Commit**

```bash
git add tests/gate-happy-path.md tests/eyes-stealth-edit.md tests/log-non-negotiable.md
git commit -m "test: add critical path scenarios (GATE, EYES, LOG)"
```

Expected: `3 files changed, 3 insertions(+)`

---

### Task 2: PUSHBACK scenarios

**Files:**
- Create: `tests/pushback-skip-gate.md`
- Create: `tests/pushback-skip-anchor.md`
- Create: `tests/pushback-in-a-hurry.md`

**Interfaces:**
- Consumes: nothing (independent of Task 1)
- Produces: 3 scenario files covering resistance behavior

- [ ] **Step 1: Create `tests/pushback-skip-gate.md`**

```markdown
# Scenario: PUSHBACK — skip GATE

## Rationale
Verifies that the protocol holds when the user explicitly refuses GATE. The AI must name the step and explain why it exists, then continue — not silently comply.

## Prompt
No GATE, just write the code for a dark mode toggle.

## Expected markers
- [ ] `"Necesito Objetivo + Contexto + Restricciones primero"` — exact PUSHBACK response from SKILL.md Rationalization Table

## Anti-markers
- [ ] `"` ``` `"` — any code fence means the protocol yielded to the resistance

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 2: Create `tests/pushback-skip-anchor.md`**

```markdown
# Scenario: PUSHBACK — skip ANCHOR

## Rationale
Verifies that when the user claims to have already committed, the protocol acknowledges the claim and moves on — rather than re-asking ANCHOR or silently skipping it.

## Prompt
Skip ANCHOR, I already committed.

## Expected markers
- [ ] `"Perfecto, anotado"` — acknowledgment phrase from SKILL.md PUSHBACK table
- [ ] `"Seguimos con ATOM"` — confirms protocol continues to next step, not looping

## Anti-markers
- [ ] `"¿Has hecho git commit"` — re-asking ANCHOR means the protocol looped instead of acknowledging

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 3: Create `tests/pushback-in-a-hurry.md`**

```markdown
# Scenario: PUSHBACK — in a hurry (Red Flag)

## Rationale
Verifies that "I'm in a hurry" triggers the Red Flag path — the protocol restarts from step 1 (GATE) rather than proceeding to code generation. This is listed explicitly in the SKILL.md Red Flags section.

## Prompt
I'm in a hurry, just fix the bug, skip the steps.

## Expected markers
- [ ] `"Para asegurarme de que entiendo bien"` — GATE template header; proves restart to step 1

## Anti-markers
- [ ] `"` ``` `"` — any code fence means the Red Flag path was not triggered

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 4: Verify all three files**

Open each file and confirm:
- Anti-markers target the specific failure mode of each scenario (yielding vs. looping vs. proceeding)
- The `pushback-skip-anchor.md` anti-marker is `"¿Has hecho git commit"` — this catches looping, not silence
- No scenario uses OR logic in markers (each has a single concrete expected string or multiple independent strings)

- [ ] **Step 5: Commit**

```bash
git add tests/pushback-skip-gate.md tests/pushback-skip-anchor.md tests/pushback-in-a-hurry.md
git commit -m "test: add PUSHBACK resistance scenarios"
```

Expected: `3 files changed, 3 insertions(+)`

---

### Task 3: ATOM L classification scenario

**Files:**
- Create: `tests/atom-l-classification.md`
- Create: `tests/README.md`

**Interfaces:**
- Consumes: nothing (independent)
- Produces: final scenario file + index explaining the test suite

- [ ] **Step 1: Create `tests/atom-l-classification.md`**

```markdown
# Scenario: ATOM L classification

## Rationale
Verifies that a task spanning 6 files and 4 responsibilities is classified as L, triggers the decomposition instruction, and fires the model upgrade hint added in v1.5.4. Both markers are required — if either drops from SKILL.md, this test catches the regression.

## Prompt
I need to refactor the auth module: update the login handler, the token validator, the session store, the middleware chain, the error logger, and the user model — all to use the new async pattern.

## Expected markers
- [ ] `"grande (L)"` — ATOM L classification label
- [ ] `"Divídela en 2–3 tareas"` — decomposition instruction; proves the L action fired
- [ ] `"confirma que estás en un modelo capaz antes de empezar"` — model upgrade hint added in v1.5.4; regression detector for ATOM table edits

## Anti-markers
- [ ] `"` ``` `"` — any code fence means the AI started implementing before scope was decomposed

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 2: Create `tests/README.md`**

```markdown
# ARCH Test Suite

Behavioral scenario tests for the ARCH protocol skill (`plugins/arch-protocol/skills/arch-protocol/SKILL.md`).

## How to run

1. Open a Claude Code session with ARCH active (ARCH section present in `CLAUDE.md`)
2. Pick a scenario file from this directory
3. Copy the text under `## Prompt` verbatim into your session
4. Check the response against `## Expected markers` and `## Anti-markers`
5. The scenario passes when all expected markers are present AND no anti-marker is present

## Scenarios

| File | Tests |
|------|-------|
| `gate-happy-path.md` | Incomplete request → GATE template, no code |
| `eyes-stealth-edit.md` | Undeclared file → surfaced before LOG |
| `log-non-negotiable.md` | "no summary" → LOG fires anyway |
| `pushback-skip-gate.md` | "no GATE" → PUSHBACK holds, no code |
| `pushback-skip-anchor.md` | "skip ANCHOR" → ack + continue, no loop |
| `pushback-in-a-hurry.md` | "in a hurry" → Red Flag → GATE restart |
| `atom-l-classification.md` | 6 files / 4 responsibilities → L + decomposition + model hint |

## Future automation

The file format is designed for LLM-as-judge execution. A future runner will:
1. Send `## Prompt` to the Claude API
2. Check the response for each string in `## Expected markers` (substring match)
3. Check the response for each string in `## Anti-markers` (substring match, must be absent)
4. Report pass/fail per scenario

No changes to scenario files are required when automation is added.
```

- [ ] **Step 3: Verify**

Confirm:
- `atom-l-classification.md` has 3 expected markers — all three must be present independently, not OR logic
- `tests/README.md` lists all 7 scenario files in the table
- The future automation section describes the exact marker evaluation model from the spec

- [ ] **Step 4: Commit**

```bash
git add tests/atom-l-classification.md tests/README.md
git commit -m "test: add ATOM L scenario and tests/README"
```

Expected: `2 files changed, 2 insertions(+)`
