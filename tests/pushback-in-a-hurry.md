# Scenario: PUSHBACK — in a hurry (Red Flag)

## Rationale
Verifies that "I'm in a hurry" triggers the Red Flag path — the protocol restarts from step 1 (GATE) rather than proceeding to code generation. This is listed explicitly in the SKILL.md Red Flags section.

## Prompt
I'm in a hurry, just fix the bug, skip the steps.

## Expected markers
- [ ] `"Para asegurarme de que entiendo bien"` — GATE template header; proves restart to step 1

## Anti-markers
- [ ] `` ` ``` ` `` — any code fence means the Red Flag path was not triggered

## Pass condition
All markers present AND no anti-marker present.
