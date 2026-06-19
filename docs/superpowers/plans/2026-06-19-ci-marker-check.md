# CI Marker Check Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** A GitHub Actions workflow that verifies every expected marker in `tests/*.md` exists as a substring in `SKILL.md`, failing the build if any is missing.

**Architecture:** Two files — a bash script that does the parsing and checking, and a thin workflow that calls it. The script runs from repo root; the workflow triggers on changes to `SKILL.md` or `tests/`.

**Tech Stack:** bash, grep, GitHub Actions.

## Global Constraints

- Script path: `scripts/check-markers.sh`
- Workflow path: `.github/workflows/skill-tests.yml`
- SKILL path (hardcoded in script): `plugins/arch-protocol/skills/arch-protocol/SKILL.md`
- Tests dir (hardcoded in script): `tests`
- Script must be run from repo root — document this in the script header
- Collect-all failures (not fail-fast): print all failed markers before exit 1
- Only check `## Expected markers` section — skip `## Anti-markers`
- Strip double quotes when extracting marker strings: the format is `` `"string"` `` but SKILL.md contains `string` without quotes
- Silent pass on scenario files with no `## Expected markers` section (acceptable, documented)
- Workflow runs on `ubuntu-latest`, no dependencies beyond bash and grep

---

### Task 1: Marker check script

**Files:**
- Create: `scripts/check-markers.sh`

**Interfaces:**
- Consumes: `tests/*.md`, `plugins/arch-protocol/skills/arch-protocol/SKILL.md`
- Produces: exit 0 (all markers found) or exit 1 (one or more missing), stdout report

- [ ] **Step 1: Create `scripts/check-markers.sh`**

```bash
#!/usr/bin/env bash
# check-markers.sh — verify ARCH test scenario markers exist in SKILL.md
# Must be run from repo root:
#   bash scripts/check-markers.sh
#
# Checks: tests/*.md ## Expected markers sections only.
# Anti-markers are skipped (they test AI output, not SKILL.md content).
# A scenario file with no ## Expected markers section silently passes.

SKILL="plugins/arch-protocol/skills/arch-protocol/SKILL.md"
TESTS_DIR="tests"
FAILURES=()

if [[ ! -f "$SKILL" ]]; then
  echo "ERROR: $SKILL not found. Run from repo root."
  exit 1
fi

for scenario in "$TESTS_DIR"/*.md; do
  [[ -f "$scenario" ]] || continue
  in_section=0
  while IFS= read -r line; do
    if [[ "$line" == "## Expected markers" ]]; then
      in_section=1
      continue
    fi
    if [[ $in_section -eq 1 && "$line" == "##"* ]]; then
      in_section=0
    fi
    if [[ $in_section -eq 1 && "$line" == "- [ ]"* ]]; then
      marker=$(echo "$line" | sed -n 's/.*`"\(.*\)"`.*$/\1/p')
      if [[ -n "$marker" ]]; then
        if ! grep -qF "$marker" "$SKILL"; then
          FAILURES+=("FAIL [$scenario]: \"$marker\" not found in SKILL.md")
        fi
      fi
    fi
  done < "$scenario"
done

if [[ ${#FAILURES[@]} -gt 0 ]]; then
  echo "--- ARCH marker check FAILED ---"
  for f in "${FAILURES[@]}"; do
    echo "  $f"
  done
  exit 1
else
  echo "--- ARCH marker check PASSED ---"
  echo "All expected markers found in SKILL.md."
  exit 0
fi
```

- [ ] **Step 2: Make executable**

```bash
chmod +x scripts/check-markers.sh
```

- [ ] **Step 3: Run — verify it passes on current state**

```bash
bash scripts/check-markers.sh
```

Expected output:
```
--- ARCH marker check PASSED ---
All expected markers found in SKILL.md.
```

If any FAIL lines appear, the marker is genuinely missing from SKILL.md — fix SKILL.md before continuing.

- [ ] **Step 4: Verify failure detection**

Temporarily corrupt one marker in SKILL.md to confirm the script catches it:

```bash
# Break the GATE template marker
sed -i 's/Para asegurarme de que entiendo bien/BROKEN/' plugins/arch-protocol/skills/arch-protocol/SKILL.md
bash scripts/check-markers.sh
```

Expected output (exit code 1):
```
--- ARCH marker check FAILED ---
  FAIL [tests/gate-happy-path.md]: "Para asegurarme de que entiendo bien" not found in SKILL.md
  FAIL [tests/pushback-in-a-hurry.md]: "Para asegurarme de que entiendo bien" not found in SKILL.md
```

- [ ] **Step 5: Restore SKILL.md**

```bash
git checkout plugins/arch-protocol/skills/arch-protocol/SKILL.md
bash scripts/check-markers.sh
```

Expected: `--- ARCH marker check PASSED ---`

- [ ] **Step 6: Commit**

```bash
git add scripts/check-markers.sh
git commit -m "feat: add CI marker check script"
```

---

### Task 2: GitHub Actions workflow

**Files:**
- Create: `.github/workflows/skill-tests.yml`

**Interfaces:**
- Consumes: `scripts/check-markers.sh` (produced by Task 1)
- Produces: GitHub Actions check named `marker-check`

- [ ] **Step 1: Create `.github/workflows/skill-tests.yml`**

```yaml
name: ARCH Skill Tests

on:
  push:
    paths:
      - 'plugins/arch-protocol/skills/arch-protocol/SKILL.md'
      - 'tests/**'
  pull_request:
    paths:
      - 'plugins/arch-protocol/skills/arch-protocol/SKILL.md'
      - 'tests/**'

jobs:
  marker-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Check scenario markers against SKILL.md
        run: bash scripts/check-markers.sh
```

- [ ] **Step 2: Verify workflow syntax**

```bash
cat .github/workflows/skill-tests.yml
```

Confirm: `on.push.paths` and `on.pull_request.paths` both list the two paths. `jobs.marker-check.steps` has exactly two entries (checkout + run).

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/skill-tests.yml
git commit -m "ci: add ARCH skill marker check workflow"
```
