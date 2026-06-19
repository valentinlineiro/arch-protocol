# ATOM Model Hints Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add symmetric model-selection hints to the ATOM step — a downgrade hint for S tasks and an upgrade hint for L tasks — so users are prompted to switch models at the moment scope is known, before any code is generated.

**Architecture:** Single-file edit to the ATOM table in SKILL.md. No new steps, no config, no branching. Two sentences appended to existing S and L Action cells.

**Tech Stack:** Markdown

## Global Constraints

- Protocol language in user-facing hints is Spanish (default lang: es per SKILL.md Language Design section)
- M row must not be touched
- Hints are advisory only — no enforcement language, no conditional logic
- The S row's compressed format code block (`🎯 GATE+PULL (S): ...`) stays intact; the hint is appended after it

---

### Task 1: Add model hints to ATOM table in SKILL.md

**Files:**
- Modify: `plugins/arch-protocol/skills/arch-protocol/SKILL.md` (ATOM section, lines ~46–53)

**Interfaces:**
- Consumes: existing ATOM table (3 rows: L, M, S)
- Produces: same table with hint sentences appended to L and S Action cells

- [ ] **Step 1: Locate the ATOM table**

Open `plugins/arch-protocol/skills/arch-protocol/SKILL.md` and find the ATOM table. It begins with:

```
| Size | Criteria | Action |
|------|----------|--------|
| **L** | >5 files or >3 responsibilities | ...
```

Confirm current L and S Action cell content before editing.

- [ ] **Step 2: Edit the L row**

Find this exact text in the L row Action cell:
```
*"Esta tarea es grande (L). Divídela en 2–3 tareas S/M primero. ¿Cómo prefieres proceder?"* Do not generate code until scope is agreed.
```

Replace with:
```
*"Esta tarea es grande (L). Divídela en 2–3 tareas S/M primero. ¿Cómo prefieres proceder?"* *"Esta tarea es grande — confirma que estás en un modelo capaz antes de empezar."* Do not generate code until scope is agreed.
```

- [ ] **Step 3: Edit the S row**

Find this exact text in the S row Action cell (the line ends after the backtick):
```
Run all 7 steps, but compress GATE + PULL into one block: `🎯 GATE+PULL (S): [goal in one sentence] · [file] · [constraint if any]`
```

Replace with:
```
Run all 7 steps, but compress GATE + PULL into one block: `🎯 GATE+PULL (S): [goal in one sentence] · [file] · [constraint if any]` *"Esta tarea es pequeña — considera cambiarte a un modelo más rápido/económico si está disponible."*
```

- [ ] **Step 4: Verify M row is unchanged**

Confirm the M row Action cell still reads exactly:
```
Run all 7 steps at full length.
```

- [ ] **Step 5: Verify the Session State section for S task note**

The Session State section contains a note about S tasks and PULL compression. Confirm it is unchanged — the model hint does not affect that note.

- [ ] **Step 6: Commit**

```bash
git add plugins/arch-protocol/skills/arch-protocol/SKILL.md
git commit -m "feat: add symmetric model hints to ATOM step (S/M/L)"
```

Expected output: `1 file changed, 2 insertions(+), 2 deletions(-)`
