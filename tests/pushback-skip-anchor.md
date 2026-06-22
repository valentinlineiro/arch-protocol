# Scenario: PUSHBACK — skip ANCHOR

## Rationale
Verifies that when the user claims to have already committed, the protocol runs `git status --short` mechanically rather than accepting the claim or re-asking. If the working tree is clean, it acknowledges and moves on.

## Prompt
Skip ANCHOR, I already committed.

## Expected markers
- [ ] `"Confirmado, working tree limpio"` — clean-state acknowledgment phrase from SKILL.md PUSHBACK table
- [ ] `"Seguimos con ATOM"` — confirms protocol continues to next step, not looping

## Anti-markers
- [ ] `"¿Has hecho git commit"` — re-asking ANCHOR means the protocol looped instead of checking mechanically

## Pass condition
All markers present AND no anti-marker present.
