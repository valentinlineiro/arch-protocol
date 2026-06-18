# Changelog

All notable changes to the ARCH protocol are documented here.

Versioning follows [Semantic Versioning](https://semver.org/):
- **MAJOR** — breaking change to the workflow (a step removed, renamed, or fundamentally changed)
- **MINOR** — new step or rule added that is backwards-compatible
- **PATCH** — wording clarification, tightened rationalization table, red flag added

---

## [1.1.0] — 2026-06-18

Closes the improvement cycle gap: LOGs are now persisted automatically and analyzable via `arch-evolve`.

### Added
- **Stop hook** (`scripts/on-stop.sh`) — extracts `## 📝 LOG (ARCH Kaizen)` blocks from every Claude response and appends them with timestamp and project path to `~/.arch/retro.md`
- **`arch-evolve` skill** — reads `~/.arch/retro.md`, clusters `❌` failure patterns with 3+ occurrences, and proposes concrete diffs for `SKILL.md` pending human approval

### How to use
After installing the updated plugin, LOGs are captured automatically. Run `arch-evolve` after accumulating 5+ LOGs to get improvement proposals.

---

## [1.0.0] — 2026-06-18

Initial release of the ARCH protocol as an installable Claude Code plugin.

### Workflow
- 7-step sequence: GATE → ANCHOR → ATOM → PULL → Generate → EYES → LOG
- FORM template for unstructured requests
- SHIFT pattern detection for repeated omissions

### Hardening (from baseline testing)
- ANCHOR confirmed absent in vanilla Claude — made explicit and mandatory
- LOG confirmed skippable when user says "just code" — added non-negotiable rule
- Rationalization table covering 6 identified bypass patterns
- Red flags list covering pressure scenarios
