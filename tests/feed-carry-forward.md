# Scenario: FEED carry-forward from M task incident

## Rationale
Verifies that FEED fires before GATE and surfaces a carried constraint from the previous task's LOG.
The constraint from the last M-task ❌/🔄 fields must appear in the FEED block before GATE runs.
The carried constraint must also appear in GATE's Constraints field.

## Prompt
Here is the session context:

Previous task logged this to retro.md:
<!-- ARCH LOG | 2026-06-23 15:42 | /proj -->
## 📝 LOG (ARCH Kaizen)
- ✅ What assumption did you make: Assumed the config was loaded before the handler ran
- ❌ What failed or caused friction: Config not yet loaded — handler read undefined values
  🤔 Why #1: initialization order not checked
- 🔄 What you'd do differently next time: Always verify config is initialized before calling handlers
- Commit: `fix: ensure config loads before handler`

Now I want to add a new feature: add a /health endpoint to the Express app.

## Expected markers
- [ ] `"🔄 FEED:"` — FEED step fired and surfaced the carry-forward block
- [ ] `"Calibrated Prior:"` — assumption field is present
- [ ] `"Constraint:"` — constraint field is present
- [ ] `"Always verify config is initialized"` — exact constraint text carried forward

## Anti-markers
- [ ] `"To make sure I understand correctly"` — GATE must not fire before FEED

## Pass condition
All markers present AND no anti-marker present.
