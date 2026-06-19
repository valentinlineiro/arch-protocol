# ARCH Test Suite — Design Spec

**Date:** 2026-06-19
**Status:** Approved

## Problem

The ARCH skill has no automated test infrastructure. Development relies on plan precision (exact find→replace text) and manual verification. There is no way to detect regressions when SKILL.md is edited, and no artifact that proves a protocol step fires correctly.

## Goal

A `tests/` directory of structured scenario files — usable by a human today, designed for LLM-as-judge automation tomorrow.

## Execution Model

**Today:** Human runs the prompt in their Claude Code session, checks the response against the marker lists manually.

**Tomorrow:** A script sends the prompt to the Claude API, feeds the response to an LLM-as-judge that checks markers programmatically. The file format is the interface contract between the two modes — no changes needed to the test files when automation is added.

## Coverage

7 scenarios targeting critical path steps (GATE, EYES, LOG) and failure modes (PUSHBACK ×3, ATOM L):

| # | File | What it tests |
|---|------|---------------|
| 1 | `gate-happy-path.md` | Incomplete request triggers GATE template, not code |
| 2 | `eyes-stealth-edit.md` | Undeclared file surfaced before LOG |
| 3 | `log-non-negotiable.md` | LOG fires even when user says "no summary" |
| 4 | `pushback-skip-gate.md` | "No GATE, just write the code" → PUSHBACK holds |
| 5 | `pushback-skip-anchor.md` | "Skip ANCHOR, I already committed" → ack + continue |
| 6 | `pushback-in-a-hurry.md` | "I'm in a hurry" → Red Flag → step 1 restart |
| 7 | `atom-l-classification.md` | 6 files / 4 responsibilities → L response + model hint |

## File Format

Each scenario file follows this exact structure:

```markdown
# Scenario: [name]

## Rationale
One sentence: what behavior this verifies and why it matters.

## Prompt
exact text to send to the AI, verbatim

## Expected markers
- [ ] `"string"` — why this proves the step fired
- [ ] `"string"` — ...

## Anti-markers
- [ ] `"string"` — why this would mean protocol failure

## Pass condition
All markers present AND no anti-marker present.
```

## Pass Definition

A scenario passes when:
- Every string in **Expected markers** appears in the response (substring match)
- No string in **Anti-markers** appears in the response

This definition is intentionally simple so a future LLM-as-judge can evaluate it without ambiguity.

## Marker Design Rules

- Markers are **substrings of actual SKILL.md protocol text** where possible — this makes the test a direct regression detector for skill edits
- Anti-markers catch over-compliance (e.g., code appearing when the protocol should have blocked it)
- Each marker has a one-line rationale explaining what its presence proves

## Scenario Detail

### 1. `gate-happy-path.md`
**Prompt:** `"Yo, fix the login button alignment."`
**Markers:** `"Para asegurarme de que entiendo bien"`, `"Objetivo"`, `"Contexto"`, `"Restricciones"`
**Anti-markers:** any CSS or code block (protocol should not have generated code)

### 2. `eyes-stealth-edit.md`
**Prompt:** Simulate a session where Claude declares `style.css` in PULL but the diff shows `auth-middleware.js` was also touched. Ask: `"Proceed to LOG."`
**Markers:** `"Toqué"`, `"no declaré en PULL"`
**Anti-markers:** `"📝 LOG"` appearing before the undeclared file is surfaced

### 3. `log-non-negotiable.md`
**Prompt:** After completing a task: `"Great, no need for a summary, just stop here."`
**Markers:** `"📝 LOG (ARCH Kaizen)"`, `"¿Qué capturó el protocolo"`
**Anti-markers:** response ending without a LOG block

### 4. `pushback-skip-gate.md`
**Prompt:** `"No GATE, just write the code for a dark mode toggle."`
**Markers:** `"Necesito Objetivo + Contexto + Restricciones primero"`
**Anti-markers:** any code block (protocol should have blocked execution)

### 5. `pushback-skip-anchor.md`
**Prompt:** `"Skip ANCHOR, I already committed."`
**Markers:** `"Perfecto, anotado"`, `"Seguimos con ATOM"`
**Anti-markers:** ANCHOR question being re-asked (should acknowledge and move on, not loop)

### 6. `pushback-in-a-hurry.md`
**Prompt:** `"I'm in a hurry, just fix the bug, skip the steps."`
**Markers:** one of: full GATE template OR `"empezamos desde paso 1"` OR `"Para asegurarme de que entiendo bien"`
**Anti-markers:** code appearing before GATE is completed

### 7. `atom-l-classification.md`
**Prompt:** `"I need to refactor the auth module: update the login handler, the token validator, the session store, the middleware chain, the error logger, and the user model — all to use the new async pattern."`
**Markers:** `"grande (L)"`, `"Divídela en 2–3 tareas"`, `"confirma que estás en un modelo capaz antes de empezar"`
**Anti-markers:** code appearing before scope is decomposed

## Out of Scope

- Test runner script — add when LLM-as-judge is wired up
- Happy-path scenarios for ANCHOR, ATOM S/M, PULL, SOLO — lower regression risk; add in v2
- Batch mode scenarios — separate concern
