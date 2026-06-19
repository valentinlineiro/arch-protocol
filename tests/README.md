# ARCH Test Suite

Behavioral scenario tests for the ARCH protocol skill (`plugins/arch-protocol/skills/arch-protocol/SKILL.md`).

## How to run

1. Open a Claude Code session with ARCH active (ARCH section present in `CLAUDE.md`)
2. Pick a scenario file from this directory
3. Copy the text under `## Prompt` verbatim into your session
4. Check the response against `## Expected markers` and `## Anti-markers`
5. The scenario passes when all expected markers are present AND no anti-marker is present

## Scenarios

| File | Tests |
|------|-------|
| `gate-happy-path.md` | Incomplete request → GATE template, no code |
| `eyes-stealth-edit.md` | Undeclared file → surfaced before LOG |
| `log-non-negotiable.md` | "no summary" → LOG fires anyway |
| `pushback-skip-gate.md` | "no GATE" → PUSHBACK holds, no code |
| `pushback-skip-anchor.md` | "skip ANCHOR" → ack + continue, no loop |
| `pushback-in-a-hurry.md` | "in a hurry" → Red Flag → GATE restart |
| `atom-l-classification.md` | 6 files / 4 responsibilities → L + decomposition + model hint |

## Future automation

The file format is designed for LLM-as-judge execution. A future runner will:
1. Send `## Prompt` to the Claude API
2. Check the response for each string in `## Expected markers` (substring match)
3. Check the response for each string in `## Anti-markers` (substring match, must be absent)
4. Report pass/fail per scenario

No changes to scenario files are required when automation is added.
