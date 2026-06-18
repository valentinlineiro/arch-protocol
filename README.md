# ARCH Protocol

**"The best prompt is the one you never have to write."**

AI chaos isn't fixed with better AI. It's fixed with better process.

---

## What is ARCH?

**ARCH (Autonomous Routing & Context Hierarchy)** is a discipline protocol for AI-assisted software development. It's inspired by the Toyota Production System (TPS) and translates its principles into the language of Git, prompts, and AI agents.

**The problem it solves:**
AI coding assistants are fast but chaotic. They write code without knowing which files exist, start massive refactors without a Git checkpoint, and leave no trace of what changed or why. You end up with fast output and slow debugging.

**The solution:**
ARCH imposes a 7-step workflow that Claude follows on every task — regardless of how urgent it feels. It's not a better prompt. It's a protocol that makes any prompt work better.

---

## The 7 Steps of ARCH

| Step | What it forces Claude to do |
| :--- | :--- |
| **GATE** | Claude must state in its own words the goal, the files, and the constraints **before writing any code**. If it doesn't understand, it asks. This is a hallucination filter. |
| **ANCHOR** | Confirms a Git commit exists as a restore point before starting. No safety net, no change. |
| **ATOM** | If the task is large (more than 5 files or 3 responsibilities), Claude suggests splitting it into smaller pieces (S/M/L sizing). |
| **PULL** | Explicitly declares which files it will read before writing. No implicit context. |
| **Generate** | Produces one logical change only. One commit per task. |
| **EYES** | Reminds you to review the `git diff` and not trust the AI's summary. Final responsibility is yours. |
| **LOG** | Closes every task with a 3-line kaizen retrospective: what worked, what failed, what you'd change. This builds a learning record that improves future tasks and gives you data to evolve your own process. |

---

## Why it works

Most problems with AI-assisted development aren't model problems — they're **process problems**. The same mistakes repeat: lost context, no Git safety net, tasks too large to review, no institutional memory.

ARCH borrows TPS's answer to the same problem in manufacturing: **stop the line before defects multiply**.

- **GATE** stops Claude from generating code it can't ground.
- **ANCHOR** prevents unrecoverable changes.
- **LOG** creates a daily record you can actually learn from.

The protocol is deliberately resistant to pressure. When you say *"just write the fix, I have a demo in 2 hours"*, ARCH doesn't comply — it runs **GATE** first, because that's exactly the moment when skipping it causes the most damage.

---

## Why I built it

> *"I built ARCH because I was tired of spending more time debugging AI-generated code than writing it. After 6 months of daily use, I've reduced my context-loss errors by 80%. This is the protocol I wish I'd had from day one."*
>
> — Valentín Liñeiro, creator of ARCH.

---

## Installation

Add the marketplace, then install the plugin:

```bash
/plugin add-marketplace https://github.com/valentinlineiro/arch-protocol
/plugin install arch-protocol@arch-protocol
```

Then invoke it:

```
"Let's work on X using ARCH"
```

### What to expect after installation

Once installed, ARCH runs in the background. You'll notice Claude starts asking for context before writing code, and every task ends with a short retrospective. You don't have to think about ARCH — it just makes your AI assistant feel more… professional.

---

## The ARCH Manifesto

> *"The best punch is the one never thrown.*
> *The best prompt is the one never written.*
>
> *ARCH is not a better prompt.*
> *It's a protocol that makes any prompt work better."*

---

## Community & contributions

ARCH is open and community-driven.

- **Try it for a week.**
- If it saves you time, open an issue with your use case.
- If it doesn't, open an issue telling me why. I'm iterating based on real feedback.

**Contributions and forks are welcome.**

---

**Designed by Valentín Liñeiro.**
