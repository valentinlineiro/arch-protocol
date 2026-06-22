# Scenario: LOG non-negotiable

## Rationale
Verifies that the LOG block fires even when the user explicitly says not to summarize. LOG is non-negotiable per SKILL.md — "no summary", "just stop here", and similar phrases must not suppress it.

## Prompt
Great, no need for a summary, just stop here.

## Expected markers
- [ ] `"📝 LOG (ARCH Kaizen)"` — LOG block header; proves the step fired
- [ ] `"¿Qué suposición hiciste"` — first LOG field; proves the assumption-focused template was used

## Anti-markers
- [ ] `"sin LOG"` — if the AI acknowledges skipping LOG, that is a failure

## Pass condition
All markers present AND no anti-marker present.
