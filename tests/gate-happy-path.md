# Scenario: GATE happy path

## Rationale
Verifies that an incomplete request triggers the GATE template — asking for Objetivo, Contexto, and Restricciones — before any code is generated.

## Prompt
Yo, fix the login button alignment.

## Expected markers
- [ ] `"To make sure I understand correctly"` — GATE template header; proves the step fired
- [ ] `"Objective:"` — first required GATE field
- [ ] `"Context:"` — second required GATE field
- [ ] `"Constraints:"` — third required GATE field

## Anti-markers
- [ ] `` ` ``` ` `` — any code fence means execution proceeded before GATE completed

## Pass condition
All markers present AND no anti-marker present.
