#!/usr/bin/env python3
"""
check-skill-integrity.py — validate SKILL.md against behavioral spec rules.

Usage: python3 scripts/check-skill-integrity.py
Must be run from repo root.

Rule types:
  step_must_contain         text must appear within a workflow step (ANCHOR, EYES, etc.)
  step_must_not_contain     text must NOT appear within a workflow step
  section_must_contain      text must appear within a top-level ## section
  section_must_not_contain  text must NOT appear within a top-level ## section
  global_must_contain       text must appear anywhere in SKILL.md
  global_must_not_contain   text must NOT appear anywhere in SKILL.md
  global_must_not_match     regex must NOT match anywhere in SKILL.md
  cross_section_phrase_match  phrase must appear in ALL listed sections/steps
"""

import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML not installed. Run: pip install pyyaml")
    sys.exit(1)


SPEC_PATH = Path("specs/skill-behavioral-spec.yaml")
SKILL_DEFAULT = Path("plugins/arch-protocol/skills/arch-protocol/SKILL.md")


def strip_fenced_blocks(content: str) -> str:
    """Remove content inside fenced code blocks (``` ... ```) to avoid false matches."""
    return re.sub(r'```.*?```', lambda m: '\n' * m.group(0).count('\n'), content, flags=re.DOTALL)


def parse_skill(content: str) -> tuple[dict[str, str], dict[str, str]]:
    """
    Parse SKILL.md into:
      sections: { section_name_lower -> content }
      steps:    { step_name_upper -> content }

    Sections are split on '## ' at line start (fenced code blocks stripped first).
    Steps are extracted from the Workflow section, split on '**N. STEP_NAME**'.
    """
    sections: dict[str, str] = {}
    steps: dict[str, str] = {}

    # Strip fenced code blocks so '## ' inside them doesn't create false section splits.
    # Use line numbers (not byte positions) so we can index into the original lines.
    stripped = strip_fenced_blocks(content)
    original_lines = content.splitlines(keepends=True)
    stripped_lines = stripped.splitlines()

    # Find section header line numbers using stripped content
    section_line_starts: list[tuple[int, str]] = []
    for i, line in enumerate(stripped_lines):
        m = re.match(r'^## (.+)', line)
        if m:
            section_line_starts.append((i, m.group(1).strip()))

    for i, (line_no, name) in enumerate(section_line_starts):
        end_line = section_line_starts[i + 1][0] if i + 1 < len(section_line_starts) else len(original_lines)
        sections[name.lower()] = "".join(original_lines[line_no:end_line])

    # Extract workflow steps from the Workflow section (full original content)
    workflow_content = ""
    for name, block in sections.items():
        if name.lower().startswith("workflow"):
            workflow_content = block
            break

    if workflow_content:
        # Steps are delimited by '**N. STEP_NAME**' patterns
        step_blocks = re.split(r'(?=\*\*\d+\. [A-Z]+\*\*)', workflow_content)
        for block in step_blocks:
            step_match = re.match(r'\*\*\d+\. ([A-Z]+)\*\*', block)
            if step_match:
                step_name = step_match.group(1)
                steps[step_name] = block

    return sections, steps


def resolve_target(rule: dict, sections: dict[str, str], steps: dict[str, str]) -> tuple[str | None, str]:
    """Return (content, label) for a step or section reference, or (None, error)."""
    if "step" in rule:
        step_name = rule["step"].upper()
        content = steps.get(step_name)
        if content is None:
            return None, f"step '{rule['step']}' not found in SKILL.md (parsed steps: {list(steps.keys())})"
        return content, f"step {rule['step']}"
    if "section" in rule:
        # Partial match on section name (case-insensitive)
        target = rule["section"].lower()
        for name, content in sections.items():
            if target in name:
                return content, f"section '{rule['section']}'"
        return None, f"section '{rule['section']}' not found in SKILL.md (parsed sections: {list(sections.keys())})"
    return None, "rule has neither 'step' nor 'section'"


def check_rules(spec: dict, content: str, sections: dict[str, str], steps: dict[str, str]) -> list[str]:
    failures = []

    for rule in spec.get("rules", []):
        rid = rule.get("id", "unknown")
        rtype = rule.get("type", "")

        if rtype == "step_must_contain":
            target, label = resolve_target(rule, sections, steps)
            if target is None:
                failures.append(f"FAIL [{rid}]: {label}")
            elif rule["text"] not in target:
                failures.append(f"FAIL [{rid}]: {label} must contain '{rule['text']}'")

        elif rtype == "step_must_not_contain":
            target, label = resolve_target(rule, sections, steps)
            if target is None:
                failures.append(f"FAIL [{rid}]: {label}")
            elif rule["text"] in target:
                failures.append(f"FAIL [{rid}]: {label} must NOT contain '{rule['text']}'")

        elif rtype == "section_must_contain":
            target, label = resolve_target(rule, sections, steps)
            if target is None:
                failures.append(f"FAIL [{rid}]: {label}")
            elif rule["text"] not in target:
                failures.append(f"FAIL [{rid}]: {label} must contain '{rule['text']}'")

        elif rtype == "section_must_not_contain":
            target, label = resolve_target(rule, sections, steps)
            if target is None:
                failures.append(f"FAIL [{rid}]: {label}")
            elif rule["text"] in target:
                failures.append(f"FAIL [{rid}]: {label} must NOT contain '{rule['text']}'")

        elif rtype == "global_must_contain":
            if rule["text"] not in content:
                failures.append(f"FAIL [{rid}]: SKILL.md must contain '{rule['text']}'")

        elif rtype == "global_must_not_contain":
            if rule["text"] in content:
                failures.append(f"FAIL [{rid}]: SKILL.md must NOT contain '{rule['text']}'")

        elif rtype == "global_must_not_match":
            pattern = rule.get("pattern", "")
            if re.search(pattern, content):
                matches = re.findall(pattern, content)
                failures.append(
                    f"FAIL [{rid}]: SKILL.md must NOT match /{pattern}/ "
                    f"(found {len(matches)} match(es))"
                )

        elif rtype == "cross_section_phrase_match":
            phrase = rule.get("phrase", "")
            rule_sections = rule.get("sections", [])
            missing_in = []
            for ref in rule_sections:
                # Each ref is either {step: X} or {section: X}
                target, label = resolve_target(ref, sections, steps)
                if target is None:
                    failures.append(f"FAIL [{rid}]: cannot resolve reference — {label}")
                    break
                if phrase not in target:
                    missing_in.append(label)
            if missing_in:
                failures.append(
                    f"FAIL [{rid}]: phrase '{phrase}' not found in: {', '.join(missing_in)}"
                )

        else:
            failures.append(f"WARN [{rid}]: unknown rule type '{rtype}'")

    return failures


def main() -> int:
    if not SPEC_PATH.exists():
        print(f"ERROR: spec not found at {SPEC_PATH}. Run from repo root.")
        return 1

    spec = yaml.safe_load(SPEC_PATH.read_text(encoding="utf-8"))
    skill_path = Path(spec.get("skill_path", str(SKILL_DEFAULT)))

    if not skill_path.exists():
        print(f"ERROR: SKILL.md not found at {skill_path}. Run from repo root.")
        return 1

    content = skill_path.read_text(encoding="utf-8")
    sections, steps = parse_skill(content)

    failures = check_rules(spec, content, sections, steps)

    rule_count = len(spec.get("rules", []))
    passed = rule_count - len(failures)

    if failures:
        print(f"--- ARCH skill integrity check FAILED ({passed}/{rule_count} rules passed) ---")
        for f in failures:
            print(f"  {f}")
        return 1
    else:
        print(f"--- ARCH skill integrity check PASSED ({rule_count}/{rule_count} rules) ---")
        return 0


if __name__ == "__main__":
    sys.exit(main())
