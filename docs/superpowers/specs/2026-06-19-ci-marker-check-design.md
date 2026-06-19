# CI Marker Check — Design Spec

**Date:** 2026-06-19
**Status:** Approved

## Problem

Edits to `SKILL.md` can silently drop required protocol strings — the exact strings the test scenarios verify as expected markers. No automated check exists today. The test suite is human-run.

## Goal

A free GitHub Actions workflow that runs whenever `SKILL.md` or `tests/` changes, verifies every expected marker from the test suite exists in `SKILL.md`, and fails the build if any is missing.

## What it checks

For each `tests/*.md`, the workflow checks that every string in `## Expected markers` appears in `SKILL.md` (fixed-string substring match). Anti-markers are skipped — they test for absence in AI output, not presence in the skill file; checking them against SKILL.md would produce false positives (e.g., ` ``` ` appears in SKILL.md code blocks).

## Files

| File | Responsibility |
|------|---------------|
| `.github/workflows/skill-tests.yml` | Trigger, checkout, call script, report result |
| `scripts/check-markers.sh` | Parse scenario files, grep markers, collect failures, exit 0/1 |

## Trigger

```yaml
on:
  push:
    paths:
      - 'plugins/arch-protocol/skills/arch-protocol/SKILL.md'
      - 'tests/**'
  pull_request:
    paths:
      - 'plugins/arch-protocol/skills/arch-protocol/SKILL.md'
      - 'tests/**'
```

## Script behavior

`scripts/check-markers.sh` — must be run from repo root (documented in script header):

1. Set `SKILL=plugins/arch-protocol/skills/arch-protocol/SKILL.md`
2. For each `tests/*.md`:
   - Extract the `## Expected markers` section (from that header to the next `##`)
   - For each line matching `- [ ]`, parse the quoted string between `` `" `` and `` "` ``
   - `grep -qF "$marker" "$SKILL"` — fixed-string, quiet
   - On miss: record `FAIL [file]: "$marker" not found in SKILL.md`
3. After all files: if any failures were recorded, print them all and `exit 1`; otherwise print summary and `exit 0`

**Collect-all, not fail-fast** — all failures are reported before exiting. A single broken SKILL.md edit typically breaks multiple markers; showing all failures in one run saves a round-trip.

## Known limitation

Short markers like `"Objetivo"` could produce false passes if the string appears elsewhere in SKILL.md (e.g., the Quick Reference table) even after the GATE template is removed. Acceptable for v1: the high-value markers (`"Para asegurarme de que entiendo bien"`, `"Necesito Objetivo + Contexto + Restricciones primero"`, `"confirma que estás en un modelo capaz"`) are unique enough that this does not apply to them.

## Cost

Zero. No API calls. Runs on `ubuntu-latest` with no dependencies beyond bash and grep — both present on all GitHub-hosted runners.

## Out of scope

- Anti-marker checking (requires AI output)
- Behavioral compliance testing (requires API)
- Local runner script (GitHub Actions only)
