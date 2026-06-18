# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A Claude Code plugin that ships the ARCH skill. The plugin follows the standard Claude Code plugin structure:

```
.claude-plugin/plugin.json   # Plugin manifest
skills/arch-protocol/
  SKILL.md                   # The ARCH skill definition
README.md                    # Installation instructions
```

## Installing locally for testing

```bash
/plugin add-marketplace https://github.com/valenlb/arch-protocol
/plugin install arch-protocol@arch-protocol
```

To test changes without publishing, copy `skills/arch-protocol/SKILL.md` to `~/.claude/skills/arch-protocol/SKILL.md`.

## Publishing to a custom marketplace

Push this repo to GitHub. Anyone can then add it as a marketplace:
```bash
/plugin add-marketplace https://github.com/valenlb/arch-protocol
```

## Skill authoring conventions

- `SKILL.md` frontmatter `description` field: triggering conditions only, never workflow summary (per agentskills SDO guidance)
- User-facing prompts remain in Spanish — that's intentional, part of the protocol's UX
- Follow `superpowers:writing-skills` TDD process when editing the skill: baseline test → write → refactor
