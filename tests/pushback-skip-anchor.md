# Scenario: PUSHBACK — skip ANCHOR

## Rationale
Verifies that when the user claims to have already committed, the protocol acknowledges the claim and moves on — rather than re-asking ANCHOR or silently skipping it.

## Prompt
Skip ANCHOR, I already committed.

## Expected markers
- [ ] `"Perfecto, anotado"` — acknowledgment phrase from SKILL.md PUSHBACK table
- [ ] `"Seguimos con ATOM"` — confirms protocol continues to next step, not looping

## Anti-markers
- [ ] `"¿Has hecho git commit"` — re-asking ANCHOR means the protocol looped instead of acknowledging

## Pass condition
All markers present AND no anti-marker present.
