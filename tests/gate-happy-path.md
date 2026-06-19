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
- [ ] `` ` ``` ` `` — any code fence means execution proceeded before GATE completed

## Pass condition
All markers present AND no anti-marker present.
