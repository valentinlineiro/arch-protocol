# Scenario: ANCHOR captures commit hash

## Rationale
Verifies that ANCHOR runs `git rev-parse HEAD` and notes `ANCHOR_HASH` after confirming the working tree state. This hash is used by EYES to detect intermediate commits mechanically — without asking the user. If either marker drops, this test catches the regression.

## Prompt
Quiero agregar validación al formulario de login.

## Expected markers
- [ ] `"git rev-parse HEAD"` — proves ANCHOR runs the hash capture command
- [ ] `"ANCHOR_HASH"` — proves the hash is noted for later use by EYES

## Anti-markers
- [ ] `"¿Hiciste algún commit"` — asking the user means the mechanical check regressed

## Pass condition
All markers present AND no anti-marker present.
