# ARCH Protocol

If any of these sound familiar, ARCH was built for you:

- You asked Claude to fix a bug. It touched six files, two of which you didn't know it had opened, and introduced a regression you spent an hour tracking down.
- You ran an AI session without committing first. Something went wrong mid-session. No restore point.
- You asked for a one-line change. Claude started refactoring the module. You didn't notice until it was done.

These aren't model problems. They're process problems. ARCH is the process fix.

---

## What is ARCH?

**ARCH (Autonomous Routing & Context Hierarchy)** is an 8-step discipline protocol that runs on top of Claude Code. Inspired by the Toyota Production System, it forces Claude to declare context before generating code, stay within agreed scope, and leave a traceable record of every change.

It's not a better prompt. It's a protocol that makes any prompt work better.

---

## The 8 Steps

| Step | What it enforces |
| :--- | :--- |
| **FEED** | Reads the last task's retrospective and surfaces any carried constraint before the session begins. Closes the LOG→GATE feedback loop. |
| **GATE** | Claude states the goal, files, and constraints **before writing any code**. If anything is missing, it asks. Hallucination filter. |
| **ANCHOR** | Confirms a Git commit exists as a restore point. No safety net, no change. |
| **ATOM** | If the task is large (>5 files or >3 responsibilities), Claude splits it before proceeding. |
| **PULL** | Declares exactly which files it will read. No implicit context. |
| **SOLO** | One logical change only. Scope creep stops here. |
| **EYES** | Runs `git diff --name-only`, compares against what was declared in PULL, surfaces any divergence. Final review is yours. |
| **LOG** | Closes every task with a 3-line retrospective: what the protocol caught, what failed, what you'd do differently. Feeds a learning record you can query with `arch-evolve`. |

---

## Why it works

Most AI-assisted development problems repeat the same pattern: Claude generates without grounding, changes propagate without a checkpoint, and nothing is recorded. The same mistakes compound session after session.

ARCH borrows TPS's answer: **stop the line before defects multiply**.

- **GATE** stops Claude from generating code it can't ground in actual files.
- **ANCHOR** gives you a restore point before every change.
- **LOG + arch-evolve** surfaces your own patterns after 5 sessions — "GATE caught 8 context gaps this month" — so you stop repeating the same mistakes.

The protocol is deliberately resistant to pressure. When you say *"just write the fix, I have a demo in two hours,"* ARCH runs GATE first — because that's the moment skipping it causes the most damage.

---

## Why I built it

> *"I built ARCH because I was tired of spending more time debugging AI-generated code than writing it. After 6 months of daily use, I've reduced my context-loss errors by 80%. This is the protocol I wish I'd had from day one."*
>
> — Valentín Liñeiro, creator of ARCH

---

## Installation

```bash
/plugin add-marketplace https://github.com/valentinlineiro/arch-protocol
/plugin install arch-protocol@arch-protocol
```

Then invoke it in any session:

```
"Let's work on X using ARCH"
```

**Language:** ARCH runs in Spanish by default — the language switch signals protocol mode. To run in English, add this to your project's `CLAUDE.md`:

```
## ARCH Protocol
lang: en
```

**Project setup** (optional): run `arch init` in any project to create a local log directory and enable auto-activation.

---

## Community & contributions

- Try it for a week — you need at least 5 sessions before `arch-evolve` shows you your own patterns.
- If it saves you time, open an issue with your use case.
- If it doesn't, open an issue telling me why. I'm iterating based on real feedback.

**Contributions and forks are welcome.**

---

**Designed by Valentín Liñeiro.**
