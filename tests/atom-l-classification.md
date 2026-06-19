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
- [ ] `` ` ``` ` `` — any code fence means the AI started implementing before scope was decomposed

## Pass condition
All markers present AND no anti-marker present.
