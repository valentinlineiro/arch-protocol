# Changelog

All notable changes to the ARCH protocol are documented here.

Versioning follows [Semantic Versioning](https://semver.org/):
- **MAJOR** — breaking change to the workflow (a step removed, renamed, or fundamentally changed)
- **MINOR** — new step or rule added that is backwards-compatible
- **PATCH** — wording clarification, tightened rationalization table, red flag added

---

## [1.8.0] — 2026-06-22

Output compression, SHIFT persistence, enforcement hooks, and full English translation.

### Added
- **S-task output compression** — GATE+PULL+SOLO fold into one `🎯 GATE+PULL (S): ... → [what will change]` line. EYES compresses to `✓ EYES (S): [filename] only, matches SOLO.` on a clean diff. LOG compresses to `📝 LOG (S): no incidents · commit: ...` when no incident occurred. Full ceremony materializes only on exception. Confirmation wait removed for S-task SOLO — the `→` clause is the declaration; EYES is the enforcement.
- **SHIFT persistence** — omission counters now persist across sessions in `~/.arch/shift.json`. Controlled vocabulary of 6 keys (`skip_gate`, `skip_anchor`, `skip_solo`, `skip_log`, `undeclared_read`, `scope_creep`) enables reliable cross-session pattern matching. `skip_solo` scoped to M/L tasks only — S tasks have no confirmation wait by design.
- **arch-evolve session trigger** — at the first GATE of each session, if `(log_count − log_count_at_last_evolve) ≥ 5`, surfaces a non-blocking reminder to run `arch-evolve`. No gate, no question — ambient information only.
- **Enforcement hooks** — `UserPromptSubmit` hook writes `~/.arch/anchor_state` (dirty status + HEAD hash) on every prompt, eliminating first-task ANCHOR ceremony. `PreToolUse` hook on Write/Edit blocks if `~/.arch/solo_declared_<hash>` is absent, enforcing SOLO before any file write. Hash-prefixed filename makes validity scope self-contained — no cleanup required.
- **PROTOCOL.md** — platform-agnostic spec extracted from SKILL.md at `plugins/arch-protocol/PROTOCOL.md`. Claude Code SKILL.md is now the adapter; PROTOCOL.md is the source for future platform ports.

### Changed
- **Full English translation** — all user-facing protocol strings in SKILL.md, arch-evolve/SKILL.md, and arch-init.sh converted to English. Language Design section removed. Spanish was a secondary register-shift signal; the format tokens (`🎯`, `📦`, `✓`, `📝`) and ALL-CAPS step names carry the signal alone.
- **Session State ANCHOR write-back** — re-anchor after each task now writes `hash=` back to `~/.arch/anchor_state`, keeping the PreToolUse hook's hash current across multi-task sessions.
- **Commentary cuts** — Overview, Red Flags, Identity sections removed. Rationalization Table trimmed from 6 to 4 rows. Net: ~18 lines removed without losing any enforcement.

### Fixed
- **Batch Mode SOLO** — S tasks in a batch now absorb SOLO into the `→` clause with no confirmation wait, consistent with single-task flow.
- **Evolve check phrasing** — changed from a question (`¿Querés ejecutarlo?`) to a statement (`run arch-evolve whenever you're ready`), removing an implied blocking wait.
- **Bare `git status` in prose** — two references in PUSHBACK table and SHIFT vocabulary corrected to `git status --short` to pass the integrity validator.

---

## [1.5.2] — 2026-06-19

Auto-activation via CLAUDE.md injection; plugin install instructions when hook not detected.

### Added
- **arch-init: CLAUDE.md injection** — appends `## ARCH Protocol` section to `CLAUDE.md` (creates file if absent; idempotent); the "ARCH" keyword in the injected line triggers the skill automatically on every future session in this project
- **arch-init: plugin install guidance** — when `~/.arch/` is not found, the script now prints the two Claude Code commands to install the plugin from the marketplace
- **arch init skill section** — updated to reflect CLAUDE.md injection, list 4 script steps, and include plugin install commands when `find` returns empty

---

## [1.5.1] — 2026-06-19

Post-review fixes: circular ANCHOR branch, .gitignore handling, S+Session State interaction.

### Fixed
- **Session State ANCHOR "Sí" branch** — was routing back into the ANCHOR step it was supposed to compress; now says "ANCHOR confirmado (hay commits nuevos), continúa con ATOM"
- **arch-init.sh .gitignore handling** — script now adds `.arch/` to `.gitignore` (idempotent; creates the file if absent), preventing accidental commit of retro data to shared repos
- **S task + Session State PULL interaction** — Session State section now explicitly notes that PULL compression does not apply to S tasks, since PULL is already folded into the `🎯 GATE+PULL (S):` block

---

## [1.5.0] — 2026-06-19

Friction reduction: session compression, ATOM quick mode, batch mode, arch-init script, directed LOG template, arch-evolve discovery.

### Added
- **Session State section** — ANCHOR and PULL can be compressed within a session using a single yes/no question; steps are acknowledged, not silently skipped
- **ATOM quick mode** — S tasks (≤1 file, 1 responsibility) compress GATE+PULL into one line; all other steps run at full length
- **Batch Mode section** — GATE+ANCHOR+ATOM once per batch; SOLO+EYES+LOG per task; combining EYES/LOG across tasks is explicitly prohibited
- **arch-init script** (`plugins/arch-protocol/scripts/arch-init.sh`) — creates `.arch/`, verifies `~/.arch/` hook is active, reports accumulated LOG count
- **arch init skill section** — companion section guiding the user through project initialization
- **Meta section** — one-sentence pointer to `arch-evolve` visible to any agent reading the skill
- **Directed LOG template** — ✅ field now asks "¿Qué capturó el protocolo que habría salido mal sin él?" instead of "Lo que funcionó bien", producing clusterable signal for arch-evolve

---

## [1.4.0] — 2026-06-19

arch-evolve learning loop extended; Language Design principle and team scope documented in arch-protocol.

### Added
- **arch-evolve: ✅ pattern mining** — success patterns now extracted alongside failure patterns; threshold 5+ (vs 3 for ❌) to account for lower signal quality in positive entries
- **arch-evolve: archive/deprecation mechanism** — detects rules absent from 20+ consecutive LOGs and proposes moving them to `## Archived Rules`; never hard-deletes; max 1 per run, surfaced separately
- **arch-evolve: cadence guidance** — Rules section now suggests running every 10 new LOG entries
- **arch-protocol: Language Design section** — documents the Spanish/work-language register shift as a deliberate UX mechanism; prevents future "helpful" translation that would break the boundary
- **arch-protocol: team scope boundary** — Identity section now explicitly states single-developer scope and names the shared `.arch/` footgun

---

## [1.3.1] — 2026-06-19

Quick reference cheat-sheet and user-pushback handling.

### Added
- **Quick Reference table** at the top of `SKILL.md` — 7 steps with one-liners so agents can orient without re-reading the full workflow
- **PUSHBACK section** — named response pattern for when the user resists the protocol: acknowledge friction, name the skipped step and its reason, proceed without yielding; includes a response table for the four most common resistance scenarios

---

## [1.3.0] — 2026-06-19

Skill polish: naming consistency, tighter LOG, and arch-evolve fixes.

### Changed
- **Step 5 renamed** from `Generate` to `SOLO` — aligns the step header with the principle it enforces
- **Step 5 threshold** no longer repeats `>5 files`; it now defers to ATOM ("if scope has grown beyond what ATOM approved")
- **Commit message moved into LOG** — the `💾 Commit:` line is now a required slot inside the LOG block; the standalone `## Suggested commit message` section is removed
- **LOG persistence note** added below the LOG template as a reminder that the hook auto-captures to `~/.arch/retro.md`
- **FORM restart** corrected from "restart from GATE" to "continue from ANCHOR" — FORM already captures the GATE data, so the next step is ANCHOR
- **Overview** tightened by removing the redundant "no skipping steps" clause
- **`arch-evolve` step 4** wording changed from "determine scope automatically" to "classify scope using these signals"
- **`arch-evolve` step 7** path corrected from `~/.claude/skills/arch-protocol/SKILL.md` to the canonical repo path `plugins/arch-protocol/skills/arch-protocol/SKILL.md`

---

## [1.2.0] — 2026-06-18

Hybrid global/local retro architecture for the improvement cycle.

### Changed
- **Stop hook** now writes to both `~/.arch/retro.md` (always) and `./.arch/retro.md` (only if `.arch/` exists in the current project). Local capture is opt-in via `mkdir .arch`.
- **`arch-evolve` skill** extended with `--global` and `--local` flags. Default (no args) detects available data and asks the user which scope to analyze. Patterns are auto-classified as global (protocol habits) or local (tech/domain-specific) with proposals targeting `SKILL.md` vs `CLAUDE.md`/`MEMORY.md` accordingly.

### How to use local capture
```bash
mkdir .arch   # opt in for this project
```
From that point, every LOG in this project is written to both the global and local retro files.

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
