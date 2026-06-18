---
name: arch-evolve
description: Use when the user wants to analyze accumulated ARCH LOGs, detect failure patterns, and get proposed improvements to SKILL.md
---

# arch-evolve

## Overview

Reads `~/.arch/retro.md`, clusters failure patterns from LOG entries, and proposes concrete changes to the ARCH skill. Does not apply changes — proposals require human review (EYES).

## Workflow

**1. Read retro.md**

```bash
cat ~/.arch/retro.md
```

If the file is empty or missing, tell the user: *"No hay LOGs acumulados todavía. Usa ARCH en algunas tareas primero."* Stop there.

**2. Cluster failures**

Extract all `❌` lines. Group by semantic similarity. Count occurrences. Focus on patterns that appear 3+ times — single occurrences are noise.

**3. Report**

Present findings in this format:
```
📊 Patrones detectados en [N] LOGs:

[count]× "[failure text]"
[count]× "[failure text]"
...
```

**4. Propose changes**

For each pattern with 3+ occurrences, generate a concrete proposed change to `SKILL.md`:

```
📝 Propuesta para SKILL.md:

[+] Añadir a Rationalization Table:
| "[pattern]" | [suggested counter] |

[-] Modificar regla [STEP]:
  Antes: [current wording]
  Después: [proposed wording]
```

One proposal per pattern. No more than 3 proposals total — prioritize by frequency.

**5. Ask for approval**

*"¿Aplicamos alguno de estos cambios? Di el número o 'ninguno'."*

If approved: edit `~/.claude/skills/arch-protocol/SKILL.md` with the change, then remind the user to also update the repo at `plugins/arch-protocol/skills/arch-protocol/SKILL.md` and bump the patch version.

If rejected: note the reason (if given) and suggest revisiting after more LOGs accumulate.

## Rules

- Never apply changes without explicit approval.
- Never propose more than 3 changes at once — cognitive overload defeats kaizen.
- If fewer than 5 LOGs exist, say so and suggest waiting for more data.
- Proposals must be specific and diff-like, not vague ("improve wording").
