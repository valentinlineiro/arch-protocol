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
