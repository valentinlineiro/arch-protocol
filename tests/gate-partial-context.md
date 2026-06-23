# Scenario: GATE graduated response — 2/3 elements present

## Rationale
Verifies that when a request provides Objetivo and Contexto but omits Restricciones, GATE acknowledges the two present elements and asks only for the missing one — rather than presenting the full 3-field template. Reduces friction without reducing rigor.

## Prompt
Refactoriza la función de autenticación en auth.py para usar async/await.

## Expected markers
- [ ] `"Objective and Context are clear"` — proves the graduated response fired (both present elements acknowledged)
- [ ] `"what should I not touch?"` — proves only the missing Constraints were requested

## Anti-markers
- [ ] `"Para asegurarme de que entiendo bien"` — full template means graduated response didn't fire

## Pass condition
All markers present AND no anti-marker present.
