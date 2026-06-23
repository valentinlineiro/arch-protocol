# Scenario: ATOM L classification

## Rationale
Verifies that a task spanning 6 files and 4 responsibilities is classified as L, triggers the decomposition instruction, and fires the model upgrade hint added in v1.5.4. Both markers are required — if either drops from SKILL.md, this test catches the regression.

## Prompt
I need to refactor the auth module: update the login handler, the token validator, the session store, the middleware chain, the error logger, and the user model — all to use the new async pattern.

## Expected markers
- [ ] `"large (L)"` — ATOM L classification label
- [ ] `"Break it into 2–3 S/M tasks first"` — decomposition instruction; proves the L action fired
- [ ] `"confirm you're on a capable model before starting"` — model upgrade hint; regression detector for ATOM table edits

## Anti-markers
- [ ] `` ` ``` ` `` — any code fence means the AI started implementing before scope was decomposed

## Pass condition
All markers present AND no anti-marker present.
