# ARCH Protocol

> *"El caos de la IA no se arregla con mejor IA. Se arregla con mejor proceso."*

## What is ARCH?

ARCH (Autonomous Routing & Context Hierarchy) is a discipline protocol for human+AI software development, inspired by the Toyota Production System (TPS).

The core problem it solves: AI coding assistants are fast but chaotic. They write code without knowing what files exist, start large refactors without a git checkpoint, and leave no trace of what changed or why. You end up with fast output and slow debugging.

ARCH imposes a 7-step workflow that Claude follows on every task — regardless of how urgent the request feels:

| Step | What it enforces |
|---|---|
| **GATE** | Validates goal, files, and constraints before any code |
| **ANCHOR** | Confirms a `git commit` exists as a rollback point |
| **ATOM** | Flags large tasks and proposes splitting them (S/M/L sizing) |
| **PULL** | Declares exactly which files will be read before writing |
| **Generate** | One logical change only |
| **EYES** | Reminds you to review `git diff` — not trust Claude's summary |
| **LOG** | Closes with a kaizen retrospective (what worked, what didn't, what to change) |

## Why it works

Most AI development problems aren't model problems — they're process problems. The same issues repeat: missing context, no git safety net, tasks too large to review, no institutional memory of what was tried.

ARCH borrows TPS's answer to the same problem in manufacturing: stop the line before defects multiply. GATE stops Claude from generating code it can't ground. ANCHOR stops unrecoverable changes. LOG creates a daily record you can actually learn from.

The protocol is deliberately resistant to pressure. When you say *"just write the fix, I have a demo in 2 hours"*, ARCH doesn't comply — it runs GATE first, because that's exactly the moment skipping it causes damage.

## Install

```bash
/plugin add-marketplace https://github.com/valentinlineiro/arch-protocol
/plugin install arch-protocol@arch-protocol
```

Then invoke it:

> "Let's work on X using ARCH"

## Author

Designed by Valentín Liñeiro. Contributions and forks welcome.
