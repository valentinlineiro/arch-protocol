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

**3. Cluster failures**

Extract all `❌` lines. Group by semantic similarity. Count occurrences. Only surface patterns with 3+ occurrences — single instances are noise.

**4. Classify each pattern**

For each pattern, classify scope using these signals:
- **Global** → mentions forgetting a protocol step (GATE, ANCHOR, ATOM, LOG) or a universal habit
- **Local** → mentions a specific technology, framework, API, or domain concept

If ambiguous, ask the user.

**5. Report**

```
📊 Patrones detectados en [N] LOGs ([scope]):

[count]× "[failure summary]" → [global|local]
[count]× "[failure summary]" → [global|local]
```

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
