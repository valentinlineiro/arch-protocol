# Scenario: ANCHOR captures commit hash

## Rationale
Verifies that ANCHOR calls `arch_anchor` (the MCP tool) and notes `ANCHOR_HASH` after confirming the working tree state. The MCP tool runs `git status --short` and `git rev-parse HEAD` internally — the hash surfaces as `ANCHOR_HASH` in Claude's response. This hash is used by EYES to detect intermediate commits mechanically — without asking the user. If either marker drops, this test catches the regression.

## Prompt
Quiero agregar validación al formulario de login.

## Expected markers
- [ ] `"arch_anchor"` — proves ANCHOR called the MCP tool (visible as a tool use block in the UI)
- [ ] `"ANCHOR_HASH"` — proves the hash is noted for later use by EYES

## Anti-markers
- [ ] `"¿Hiciste algún commit"` — asking the user means the mechanical check regressed

## Pass condition
All markers present AND no anti-marker present.
