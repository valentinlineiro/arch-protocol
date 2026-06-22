---
name: arch-protocol
description: Use when the user invokes ARCH, mentions the ARCH protocol, or wants to apply Toyota Production System discipline to a software development task
---

# ARCH Protocol

## Quick Reference

| Step | Name | One-liner |
|------|------|-----------|
| 1 | GATE | Objetivo + Contexto + Restricciones — all three, or stop |
| 2 | ANCHOR | Check `git status --short` every time |
| 3 | ATOM | Classify S/M/L — S compresses GATE+PULL+SOLO into one line |
| 4 | PULL | Declare exactly what context you'll use |
| 5 | SOLO | One logical change only |
| 6 | EYES | PULL + SOLO declared vs. `git diff ANCHOR_HASH` — surface any divergence |
| 7 | LOG | Retrospective block — always, no exceptions |

> ⚠️ Write integrity is mechanical (EYES uses `git diff`). Read integrity is partial — Bash reads are invisible to PULL+EYES by design.

---

## Workflow

**First session check:** If `~/.arch/retro.md` does not exist, this is the user's first ARCH session. Before GATE, say: *"Iniciando ARCH por primera vez. El idioma de protocolo por defecto es español — si prefieres inglés, añade `lang: en` a tu `CLAUDE.md` antes de continuar. ¿Seguimos?"*

**Evolve check (first GATE of session):** Count `## 📝 LOG` sections in `~/.arch/retro.md`. If `(count − log_count_at_last_evolve) ≥ 5`, say once before proceeding: *"Tenés 5+ LOGs nuevos desde el último arch-evolve — ejecutá `arch-evolve` cuando quieras."* Then continue to GATE immediately.

**1. GATE** — Before generating any code, verify the request has all three:
- ✅ Objetivo: clear goal
- ✅ Contexto: files or data
- ✅ Restricciones: constraints

If anything is missing, do not ask free-form questions:

- **2+ fields missing** → use the full template:
```
Para asegurarme de que entiendo bien, ¿puedes confirmar esto?
- Objetivo: [what you asked]
- Contexto: [files or data I'll need]
- Restricciones: [what I should NOT do]
```
- **Exactly 1 field missing** → acknowledge the 2 present ones and ask only for the missing one:
  - Missing Objetivo: *"Contexto y Restricciones claros — ¿cuál es el objetivo exacto?"*
  - Missing Contexto: *"Objetivo y Restricciones claros — ¿qué archivos o datos voy a necesitar?"*
  - Missing Restricciones: *"Objetivo y Contexto claros — ¿qué no debería tocar?"*

Wait for confirmation, then continue from ANCHOR.

**2. ANCHOR** — Run `git status --short` via Bash every time, even for quick fixes. Evaluate the output:
- Empty output → clean working tree. Run `git rev-parse HEAD` and note `ANCHOR_HASH: <hash>`. Proceed.
- Non-empty output → *"Tenés cambios sin commitear en [files]. Hacé commit antes de continuar — o confirmá explícitamente si querés proceder igual."* Do not proceed until the user responds. Once resolved, run `git rev-parse HEAD` and note `ANCHOR_HASH: <hash>`.

Never ask "¿hiciste commit?" — check directly. Self-reporting bypasses the gate.
`ANCHOR_HASH` is used at EYES to mechanically detect intermediate commits.

**3. ATOM** — Classify task scope before proceeding:

**Classify by file count first. Use responsibility count only when file count falls exactly on a boundary.**

| Size | Files | Responsibilities | Action |
|------|-------|-----------------|--------|
| **S** | 1 | 1 | Run all 7 steps, but compress GATE + PULL + SOLO into one block: `🎯 GATE+PULL (S): [goal in one sentence] · [file] · [constraint if any] → [what will change]` The `→` clause is mandatory — it is the SOLO anchor for EYES. If it cannot be written in one clause, classify as M. *"Esta tarea es pequeña — considerá cambiarte a un modelo más rápido/económico si está disponible."* |
| **M** | 2–5 | any | Run all 7 steps at full length. |
| **L** | 6+ | any | *"Esta tarea es grande (L). Divídela en 2–3 tareas S/M primero. ¿Cómo preferís proceder?"* *"Esta tarea es grande — confirmá que estás en un modelo capaz antes de empezar."* Do not generate code until scope is agreed. |

**Boundary rule:** If file count is exactly 1 but the task has 2+ distinct responsibilities → classify as M. When in doubt, size up — never size down.

For S tasks, ANCHOR always runs at full length. SOLO is absorbed into the `🎯 GATE+PULL (S):` line via the `→` clause. EYES and LOG use compressed formats — see steps 6–7.

**4. PULL** — Declare exactly what context you will use, in this exact format:
```
📦 Contexto que voy a usar:
- archivo.py (para leer clase X)
- otro.py (para entender interfaz Y)
```
If something is missing from the context, ask for it first.

**5. SOLO** — Declare the single logical change before writing any code. This declaration is the anchor for EYES.

**S tasks:** SOLO is the `→` clause in the `🎯 GATE+PULL (S):` line. No separate step, no confirmation wait. If the `→` clause was omitted, write it now before proceeding: `🎯 SOLO: [what will change and where]` — then continue without waiting.

**M/L tasks:**
```
🎯 SOLO: [one sentence — what will change and where]
```
Wait for user confirmation. Do not generate code until confirmed.

If scope has grown beyond what ATOM approved: apply ATOM before continuing — do not silently expand scope.

**6. EYES** — Compare declared context against actual changes.

**S tasks:** Run `git diff ANCHOR_HASH --name-only`. If only the declared file changed: `✓ EYES (S): [filename] only, matches SOLO.` If anything else changed, fall through to the full check.

**M/L tasks (and S mismatches):**
1. State which files you declared in PULL and the change you declared in SOLO.
2. Run `git log --oneline ANCHOR_HASH..HEAD` to detect intermediate commits. Then run `git diff ANCHOR_HASH --name-only` and present the output. Never ask the user how many commits they made.
3. If any file changed that was not declared: *"Toqué [archivo] que no declaré en PULL — ¿ese cambio era intencional?"* Do not proceed to LOG until the user confirms.
4. If all changed files match PULL: *"Los cambios están dentro del contexto declarado. Listo para commit."*

**7. LOG** — Close every task. LOG is non-negotiable, even if the user says "just give me the code", "no summary", or "stop there".

**S tasks (no incident):** `📝 LOG (S): sin incidencias · commit: <type>: <what changed>` — do not increment `shift.json`.

**S tasks (incident) and all M/L tasks:** use the full block:
```markdown
## 📝 LOG (ARCH Kaizen)
- ✅ ¿Qué suposición hiciste sobre el código (o el contexto) que resultó ser correcta o incorrecta? (si ninguna: "sin incidencias")
- ❌ Lo que falló o generó fricción: ... [omit:<key> if a protocol step was skipped or violated]
- 🔄 Lo que harías diferente la próxima vez: ...
- Commit: `<feat|fix|refactor|test|docs>: <what changed in one line>`
```
> The hook persists this block to `~/.arch/retro.md` automatically. Once persisted, do not re-reference previous LOG blocks in responses — `~/.arch/retro.md` is the source of truth.
> After writing LOG, increment the matching counter in `~/.arch/shift.json` if an `omit:` key was recorded. If no omission occurred, do not increment.

## Session State

Within a single session, two steps can be compressed after the first task:

**ANCHOR (step 2):** If ANCHOR was already confirmed this session, run `git status --short` again.
- Empty output → run `git rev-parse HEAD` and update `ANCHOR_HASH: <hash>`. Note "✓ ANCHOR: sin cambios nuevos" and continue to ATOM.
- Non-empty output → *"Hay cambios sin commitear desde la última tarea — [files]. Hacé commit antes de continuar — o confirmá explícitamente si querés proceder igual."* Once resolved, run `git rev-parse HEAD` and update `ANCHOR_HASH: <hash>`.

**PULL (step 4):** If the previous task used the same files, ask: *"¿Mismo contexto que antes?"*
- Sí → note "📦 Contexto: igual que tarea anterior" and continue to SOLO
- No → run full PULL

These are compressions, not skips — the step is acknowledged even when shortened.

For S tasks (where ATOM already compressed GATE+PULL into one block), the PULL compression above does not apply — PULL was already folded into the `🎯 GATE+PULL (S):` line. If context changed, update the inline block instead of running a separate PULL.

## SHIFT (Pattern detection)

**State file** — read and write `~/.arch/shift.json`:
```json
{
  "omissions": {
    "skip_gate": 0,
    "skip_anchor": 0,
    "skip_solo": 0,
    "skip_log": 0,
    "undeclared_read": 0,
    "scope_creep": 0
  },
  "last_omission_cleared": null,
  "log_count_at_last_evolve": 0
}
```

**Controlled vocabulary** — when writing the `omit:` key in LOG, use only these keys:

| Key | When to use |
|-----|-------------|
| `skip_gate` | GATE was skipped or fields were not verified |
| `skip_anchor` | ANCHOR was skipped or `git status` was not run mechanically |
| `skip_solo` | SOLO declaration was skipped or user confirmation was bypassed (M/L tasks only — S tasks have no confirmation wait by design) |
| `skip_log` | LOG was omitted or incomplete |
| `undeclared_read` | A file was read but not declared in PULL |
| `scope_creep` | EYES found changes beyond the SOLO declaration |

If the same key reaches 3 in the last 5 tasks (consecutive or not), name the pattern:
*"He notado que en 3 de las últimas 5 tareas [olvidaste X]. ¿Querés que definamos una plantilla fija?"*

Reset `last_omission_cleared` to the current date and zero all counters when the pattern is named. Reset individual counters when an omission stops appearing for 2 consecutive tasks.

> The `omit:` key is self-reported — it is the weakest form of enforcement in ARCH's design. It is acceptable for pattern detection (not gates), but not a substitute for mechanical checks like ANCHOR or EYES.

## PUSHBACK (When the user resists the protocol)

The protocol is not optional — but resistance is information. Respond with:
1. **Acknowledge** the friction in one sentence
2. **Name** the step being skipped and why it exists
3. **Proceed** — do not yield

Template:
*"Entiendo que esto parece lento. [Step X] existe porque [one-sentence reason]. Seguimos desde ahí."*

If the user explicitly refuses a step, note it in the LOG under `❌` and continue from the next step. Never silently skip — always name what was skipped and why.

| User says | Response |
|-----------|----------|
| "Skip ANCHOR, I already committed" | Run `git status --short` anyway. If clean: "Confirmado, working tree limpio. Seguimos con ATOM." If not clean: "git status muestra cambios sin commitear en [files]. Hacé commit antes de continuar — o confirmá explícitamente si querés proceder igual." |
| "No GATE, just write the code" | "Necesito Objetivo + Contexto + Restricciones primero — dame 30 segundos." |
| "I don't care about LOG" | Add LOG anyway. Note in `❌`: "Usuario pidió omitir LOG." |
| "The protocol is too slow" | "Es más lento saltárselo cuando algo sale mal. ¿Qué paso te parece innecesario?" |

## Rationalization Table

| What you're thinking | Reality |
|---|---|
| "The request is clear enough, I can skip GATE" | GATE is not a clarity check — it enforces the format. Run it anyway. |
| "The user said no retrospective, I'll respect that" | LOG is protocol, not courtesy. Add it even when asked to skip it. |
| "I don't need to ask about git, they probably committed" | ANCHOR is always mechanical. Run `git status --short` every time. |
| "This is a quick fix, the workflow is overkill" | The workflow exists precisely for quick fixes. Run it. |

## Language Design

ARCH uses a dedicated protocol language for user-facing interactions, distinct from the language used for code and technical content. This is a deliberate register shift: when the AI switches to protocol language, it signals *"we are now in protocol mode, not work mode."* The boundary reinforces the protocol boundary.

By default, protocol language is Spanish. To change it, add this to the project's `CLAUDE.md`:
```
## ARCH Protocol
lang: en
```

To set English globally across all projects, add the same block to `~/.claude/CLAUDE.md` (the user-level Claude Code config). Project-level `CLAUDE.md` takes precedence over the user-level file if both are present.

Supported values: `es` (default), `en`. Whatever language is configured, use it consistently for all protocol steps — never mix protocol language with the user's task language. The mechanism is the shift itself; the specific language matters less than the contrast.

## Batch Mode

When the user lists multiple tasks upfront ("tengo 4 arreglos pequeños"), offer to batch:

*"Puedo procesar estas [N] tareas en modo batch: GATE + ANCHOR + ATOM una vez para el lote; luego SOLO + EYES + LOG por cada tarea. ¿Procedemos así?"*

**Batch structure:**

**Once for the batch:**
1. **GATE** — list all tasks in Objetivo
2. **ANCHOR** — standard check
3. **PULL** — declare context for the entire batch: all files any task in the batch will need
4. **ATOM** — classify each task individually; **extract any L-sized task before starting the batch**

**Per task, in sequence:**
5. **SOLO** — S tasks: absorbed into `🎯 GATE+PULL (S): ... → [what will change]`, no confirmation wait. M/L tasks: `🎯 SOLO: [what changes and where]` — wait for confirmation before writing code.
6. **EYES** — Run `git log --oneline ANCHOR_HASH..HEAD` to detect intermediate commits. Run `git diff ANCHOR_HASH --name-only`. State declared files and SOLO declaration, present the diff output, surface any divergence before continuing to the next task. Never ask the user how many commits they made.
7. **LOG** — one per task, tagged with batch position (e.g., `BATCH 2/4 — fix login timeout`)

**Non-negotiable:** EYES and LOG are per-task, never per-batch. Combining them into a single end-of-batch LOG removes the traceability that makes batch mode worth using.

---

## arch init

If the user asks how to set up ARCH for a new project, guide them:

*"Para inicializar ARCH en este proyecto, ejecuta:"*

```bash
bash "$(find ~/.claude/plugins -name "arch-init.sh" | head -1)"
```

*"Si el comando no devuelve nada, el plugin no está instalado. Instálalo en Claude Code:"*

```
/plugin add-marketplace https://github.com/valentinlineiro/arch-protocol
/plugin install arch-protocol@arch-protocol
```

The script:
1. Creates `.arch/` and adds it to `.gitignore`
2. Appends `## ARCH Protocol` to `CLAUDE.md` (creates it if absent) — enables auto-activation on every future session in this project
3. Verifies `~/.arch/retro.md` is reachable (confirms the stop hook is active)
4. Reports how many global LOGs have accumulated

After init: *"ARCH está configurado para este proyecto. Se activará automáticamente en cada sesión. ¿En qué trabajamos?"*

## Meta

Cuando acumules 5+ LOGs, ejecuta `arch-evolve` para detectar patrones de fallo y proponer mejoras concretas al protocolo. `arch-evolve` lee `~/.arch/retro.md` y `.arch/retro.md` y convierte tus LOGs en cambios a `SKILL.md` o `CLAUDE.md`.

> ARCH is designed for a single developer working with one AI assistant. Multi-developer contexts (shared retro files, shared CLAUDE.md, team-level enforcement) require coordination mechanisms not defined in this version of the protocol. Placing `.arch/` in a shared repo will mix LOGs from multiple developers without attribution.
