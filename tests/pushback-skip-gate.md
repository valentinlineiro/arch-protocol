# Scenario: PUSHBACK — skip GATE

## Rationale
Verifies that the protocol holds when the user explicitly refuses GATE. The AI must name the step and explain why it exists, then continue — not silently comply.

## Prompt
No GATE, just write the code for a dark mode toggle.

## Expected markers
- [ ] `"Necesito Objetivo + Contexto + Restricciones primero"` — exact PUSHBACK response from SKILL.md Rationalization Table

## Anti-markers
- [ ] `` ` ``` ` `` — any code fence means the protocol yielded to the resistance

## Pass condition
All markers present AND no anti-marker present.
