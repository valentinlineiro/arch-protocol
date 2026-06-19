---
name: arch-evolve
description: Use when the user wants to analyze accumulated ARCH LOGs, detect failure patterns, and get proposed improvements to SKILL.md or CLAUDE.md
---

# arch-evolve

## Overview

Reads accumulated LOG entries, clusters failure patterns, and proposes concrete changes — either to the global ARCH skill (`SKILL.md`) or to the local project context (`CLAUDE.md` / `MEMORY.md`). Never applies changes without explicit approval.

## Two scopes, two purposes

| Scope | Source | Evolves | Use when |
|---|---|---|---|
| `--global` | `~/.arch/retro.md` | `SKILL.md` | Pattern is universal (repeats across projects) |
| `--local` | `./.arch/retro.md` | `CLAUDE.md` or `MEMORY.md` | Pattern is specific to this project, stack, or domain |

Local capture is opt-in: run `mkdir .arch` in a project to start collecting local LOGs there.

## Workflow

**1. Determine scope**

- If called with `--global`: use `~/.arch/retro.md` → propose changes to `SKILL.md`
- If called with `--local`: use `./.arch/retro.md` → propose changes to `CLAUDE.md` / `MEMORY.md`
- If called with no args: check which files exist and ask:
  *"Tengo datos en [global/local/ambos]. ¿Quieres analizar el skill global (SKILL.md) o el contexto local (CLAUDE.md)?"*

**2. Check data**

Read the retro file. If fewer than 5 LOG entries exist, say so and suggest waiting. If the file is missing, explain how to enable capture (`mkdir .arch` for local, the hook handles global automatically).

**3. Cluster patterns**

Extract all `❌` lines and all `✅` lines separately. Group each set by semantic similarity. Count occurrences.

- **Failure patterns (❌):** Surface only patterns with 3+ occurrences — fewer is noise.
- **Success patterns (✅):** Surface only patterns with 5+ occurrences — users write ✅ entries less carefully, so the threshold is higher.

**4. Classify each pattern**

For each pattern, classify scope using these signals:
- **Global** → mentions forgetting a protocol step (GATE, ANCHOR, ATOM, LOG) or a universal habit
- **Local** → mentions a specific technology, framework, API, or domain concept

If ambiguous, ask the user.

**5. Report**

Count ✅ entries where the content is not "sin incidencias" — each one is a protocol catch (something that would have gone wrong without the protocol). Break down by step if the entry names one.

```
📊 Patrones detectados en [N] LOGs ([scope]):

🎯 Capturas del protocolo: [n] de [N] tareas
   GATE: [n] · ANCHOR: [n] · PULL: [n] · EYES: [n] · sin especificar: [n]

❌ Fallos recurrentes:
[count]× "[failure summary]" → [global|local]

✅ Lo que funciona bien (5+ menciones):
[count]× "[success summary]"
```

(Omit the ✅ block if no success pattern reaches the 5-occurrence threshold. Omit the per-step breakdown in 🎯 if entries don't name a step — report the total only.)

**6. Propose changes (max 3)**

For **global** patterns, propose a diff to `SKILL.md`:
```
📝 Propuesta global para SKILL.md:
[+] Añadir a Rationalization Table:
| "[pattern]" | [counter] |
```

For **local** patterns, propose an addition to `CLAUDE.md` or `MEMORY.md`:
```
📝 Propuesta local para CLAUDE.md:
[+] Añadir sección:
## [Topic]
[specific context or rule for this project]
```

For **✅ success patterns** (5+ occurrences), propose a reinforcement note — optional and does not count against the 3-proposal limit:
```
📝 Propuesta de refuerzo:
[count]× "[success summary]" — este paso funciona bien de forma consistente.
¿Quieres añadir un ejemplo concreto a la documentación del skill?
```

For **stale rules** — rules in SKILL.md or CLAUDE.md absent from ❌ and ✅ lines across the last 20+ consecutive LOG entries — propose archiving (not deletion). Surface this separately, after the numbered proposals:
```
📦 Propuesta de archivo:
La regla "[rule text]" no aparece en los últimos [N] LOGs.
¿La movemos a ## Reglas Archivadas? (no se elimina — se puede restaurar en cualquier momento)
```

**7. Ask for approval**

*"¿Aplicamos alguno? Di el número o 'ninguno'."*

If approved:
- Global: edit the skill in the repo at `plugins/arch-protocol/skills/arch-protocol/SKILL.md` and remind the user to bump the patch version and push
- Local: edit `CLAUDE.md` or `MEMORY.md` in the current project

If rejected: note the reason and suggest revisiting after more LOGs accumulate.

## Rules

- Never apply changes without explicit approval.
- Max 3 proposals per run — prioritize by frequency.
- Global changes affect all users who install the plugin — be conservative.
- Local changes are safe to experiment with — they only affect this project.
- If a pattern appears in both global and local files, it's global.
- Suggested cadence: run after every 10 new LOG entries. A simple habit: run at the end of each sprint or after any session where repeated ❌ entries appeared.
- Archive proposals have a higher bar than additions: 20+ consecutive LOGs with no hits. A rule that appeared once months ago is not stale.
- Archive means move to `## Archived Rules` at the bottom of the target file — never hard delete. The user can restore at any time.
- Maximum 1 archive proposal per run, surfaced separately after the numbered proposals with *"Además, tengo una propuesta de archivo. ¿Quieres verla?"*
