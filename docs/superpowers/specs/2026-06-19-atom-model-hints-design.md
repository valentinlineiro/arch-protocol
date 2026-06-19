# ATOM Model Hints — Design Spec

**Date:** 2026-06-19
**Status:** Approved
**Scope:** `plugins/arch-protocol/skills/arch-protocol/SKILL.md` — ATOM table only

## Problem

ARCH's ATOM step classifies task scope (S/M/L) before any code is generated. This is the ideal moment to surface model selection advice — scope is known, no expensive work has started. Without a hint, users on heavy models run trivial S tasks at full cost, and users on light models attempt L tasks that exceed model capacity.

## Solution

Add one sentence to the Action column of the S and L rows in the ATOM table. Always-on, no config, no branching.

## ATOM Table (after change)

| Size | Criteria | Action |
|------|----------|--------|
| **L** | >5 files or >3 responsibilities | *"Esta tarea es grande (L). Divídela en 2–3 tareas S/M primero. ¿Cómo prefieres proceder?"* + *"Esta tarea es grande — confirma que estás en un modelo capaz antes de empezar."* Do not generate code until scope is agreed. |
| **M** | 2–5 files or 2–3 responsibilities | Run all 7 steps at full length. |
| **S** | ≤1 file and 1 responsibility | Run all 7 steps, but compress GATE + PULL into one block: `🎯 GATE+PULL (S): [goal in one sentence] · [file] · [constraint if any]` + *"Esta tarea es pequeña — considera cambiarte a un modelo más rápido/económico si está disponible."* |

## Rationale

- **Symmetric:** downgrade hint for S (cost), upgrade hint for L (quality). L hint is arguably higher value — an underpowered model on a complex task produces garbage and wastes more tokens than paying slightly more for a trivial fix.
- **Zero enforcement:** ARCH is a protocol layer, not a routing layer. It cannot switch models mid-session. The hint is advisory; the user acts or ignores.
- **Zero overhead:** Two sentences appended to existing rows. No new steps, no conditionals, no config flags.

## Out of scope (v2)

- Opt-in gating via `model_hints: true` in CLAUDE.md — adds branching for ~5% of users, not worth it.
- LOG-level model capture for `arch-evolve` cost-pattern mining — requires reliable self-reporting or platform-level telemetry, neither of which exists today.
