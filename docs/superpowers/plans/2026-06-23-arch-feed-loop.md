# ARCH v2.1.0 — FEED Step Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add FEED as step 1 of the ARCH protocol (closes the LOG→GATE feedback loop), backed by a new `arch_feed_read` MCP tool and an `on-stop.sh` fix that prevents ghost constraints from S-task clean logs.

**Architecture:** Three coordinated changes across two repos: (1) new `arch_feed_read` MCP tool + `skip_feed` schema in arch-mcp, published as 1.1.0; (2) `on-stop.sh` fix in arch-protocol to write clean S-task LOG lines to `retro.md`; (3) SKILL.md + PROTOCOL.md renumbering (1→8 steps) + FEED step text + plugin.json pin bump to arch-mcp 1.1.0.

**Tech Stack:** TypeScript, Vitest, Node.js fs module, bash, Claude Code plugin system.

## Global Constraints

- arch-mcp tool prefix in SKILL.md: `mcp__plugin_arch-protocol_arch-mcp__arch_feed_read`
- `arch_feed_read` returns `{ has_feed: false }` on ALL error/edge conditions — never throws
- `skip_feed` must be added to `ShiftState.omissions`, `DEFAULT_SHIFT_STATE`, and `ShiftStateSchema` in `src/schema/shift.ts`
- arch-mcp version: `1.0.0` → `1.1.0` (bump in `package.json` AND `src/index.ts` McpServer constructor)
- arch-protocol plugin version: `2.0.1` → `2.1.0` (in `plugin.json`)
- arch-mcp npm pin in plugin.json: `@valentinlineiro/arch-mcp@1.0.0` → `@valentinlineiro/arch-mcp@1.1.0`
- npm publish requires OTP — the human must run `npm publish --access public --otp=<OTP>` from `/home/valentin/code/arch-mcp`
- All 8-step references use the numbered sequence: FEED(1) GATE(2) ANCHOR(3) ATOM(4) PULL(5) SOLO(6) EYES(7) LOG(8)

---

### Task 1: arch-mcp — `arch_feed_read` tool + `skip_feed` schema + version 1.1.0

**Repo:** `/home/valentin/code/arch-mcp`

**Files:**
- Create: `src/tools/feed.ts`
- Create: `tests/tools/feed.test.ts`
- Modify: `src/schema/shift.ts` (add `skip_feed`)
- Modify: `src/index.ts` (register tool, bump version string)
- Modify: `package.json` (bump version)

**Interfaces:**
- Consumes: `resolveGlobal(filename)` from `src/lib/paths.js`, `resolveProject(filename, cwd?)` from same
- Produces: `readFeed(projectPath?: string): FeedResult` — consumed by Task 3 (SKILL.md) as `arch_feed_read` MCP tool

- [ ] **Step 1: Write the failing tests**

Create `tests/tools/feed.test.ts`:

```typescript
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { mkdirSync, rmSync, writeFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

const GLOBAL_DIR = join(tmpdir(), 'arch-mcp-feed-global');
const PROJECT_DIR = join(tmpdir(), 'arch-mcp-feed-project');
let useProject = false;

vi.mock('../../src/lib/paths.js', () => ({
  resolveGlobal: (filename: string) => join(GLOBAL_DIR, filename),
  resolveProject: (filename: string, _cwd?: string) =>
    useProject ? join(PROJECT_DIR, '.arch', filename) : null,
}));

const { readFeed } = await import('../../src/tools/feed.js');

const INCIDENT_ENTRY = `<!-- ARCH LOG | 2026-06-23 15:42 | /proj -->
## 📝 LOG (ARCH Kaizen)
- ✅ What assumption did you make: Assumed the API was synchronous
- ❌ What failed or caused friction: API requires await — call failed silently
  🤔 Why #1: didn't check the signature
- 🔄 What you'd do differently next time: Always await async calls before accessing return value
- Commit: \`fix: await the API call\`
`;

const CLEAN_FULL_ENTRY = `<!-- ARCH LOG | 2026-06-23 16:00 | /proj -->
## 📝 LOG (ARCH Kaizen)
- ✅ What assumption did you make: no incidents
- ❌ What failed or caused friction: no incidents
- 🔄 What you'd do differently next time: no incidents
- Commit: \`feat: add feature\`
`;

const CLEAN_S_ENTRY = `<!-- ARCH LOG | 2026-06-23 16:30 | /proj -->
📝 LOG (S): no incidents · commit: fix: update markers
`;

describe('readFeed — no retro files', () => {
  beforeEach(() => { useProject = false; mkdirSync(GLOBAL_DIR, { recursive: true }); });
  afterEach(() => rmSync(GLOBAL_DIR, { recursive: true, force: true }));

  it('returns has_feed: false when no retro files exist', () => {
    expect(readFeed('/proj')).toEqual({ has_feed: false });
  });
});

describe('readFeed — local retro', () => {
  beforeEach(() => {
    useProject = true;
    mkdirSync(join(PROJECT_DIR, '.arch'), { recursive: true });
  });
  afterEach(() => rmSync(PROJECT_DIR, { recursive: true, force: true }));

  it('returns has_feed: true and extracts fields from an incident entry', () => {
    writeFileSync(join(PROJECT_DIR, '.arch', 'retro.md'), INCIDENT_ENTRY);
    const result = readFeed('/proj');
    expect(result.has_feed).toBe(true);
    if (result.has_feed) {
      expect(result.constraint).toBe('Always await async calls before accessing return value');
      expect(result.calibrated_prior).toBe('Assumed the API was synchronous');
      expect(result.last_commit).toBe('fix: await the API call');
    }
  });

  it('returns has_feed: false for a clean full LOG (no incidents)', () => {
    writeFileSync(join(PROJECT_DIR, '.arch', 'retro.md'), CLEAN_FULL_ENTRY);
    expect(readFeed('/proj')).toEqual({ has_feed: false });
  });

  it('returns has_feed: false for a clean S-task LOG line', () => {
    writeFileSync(join(PROJECT_DIR, '.arch', 'retro.md'), CLEAN_S_ENTRY);
    expect(readFeed('/proj')).toEqual({ has_feed: false });
  });

  it('ghost constraint regression: incident then clean S-task → has_feed: false', () => {
    writeFileSync(join(PROJECT_DIR, '.arch', 'retro.md'), INCIDENT_ENTRY + CLEAN_S_ENTRY);
    expect(readFeed('/proj')).toEqual({ has_feed: false });
  });
});

describe('readFeed — global retro with project matching', () => {
  beforeEach(() => { useProject = false; mkdirSync(GLOBAL_DIR, { recursive: true }); });
  afterEach(() => rmSync(GLOBAL_DIR, { recursive: true, force: true }));

  const OTHER_PROJECT_INCIDENT = `<!-- ARCH LOG | 2026-06-23 12:00 | /other -->
## 📝 LOG (ARCH Kaizen)
- ✅ What assumption did you make: wrong project assumption
- ❌ What failed or caused friction: wrong project problem
- 🔄 What you'd do differently next time: wrong project constraint
- Commit: \`fix: other\`
`;

  it('finds last entry matching the project path (ignores other projects)', () => {
    writeFileSync(join(GLOBAL_DIR, 'retro.md'), OTHER_PROJECT_INCIDENT + INCIDENT_ENTRY);
    const result = readFeed('/proj');
    expect(result.has_feed).toBe(true);
    if (result.has_feed) {
      expect(result.constraint).toBe('Always await async calls before accessing return value');
    }
  });

  it('returns has_feed: false when no entries match the project path', () => {
    writeFileSync(join(GLOBAL_DIR, 'retro.md'), OTHER_PROJECT_INCIDENT);
    expect(readFeed('/proj')).toEqual({ has_feed: false });
  });

  it('ghost constraint: /proj incident + /proj clean S-task + /other incident → has_feed: false for /proj', () => {
    writeFileSync(
      join(GLOBAL_DIR, 'retro.md'),
      INCIDENT_ENTRY + CLEAN_S_ENTRY + OTHER_PROJECT_INCIDENT
    );
    expect(readFeed('/proj')).toEqual({ has_feed: false });
  });

  it('returns has_feed: false when retro.md is empty', () => {
    writeFileSync(join(GLOBAL_DIR, 'retro.md'), '');
    expect(readFeed('/proj')).toEqual({ has_feed: false });
  });
});
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd /home/valentin/code/arch-mcp && npx vitest run tests/tools/feed.test.ts
```

Expected: FAIL — `Cannot find module '../../src/tools/feed.js'`

- [ ] **Step 3: Implement `src/tools/feed.ts`**

```typescript
import { readFileSync, existsSync } from 'fs';
import { resolveGlobal, resolveProject } from '../lib/paths.js';

export type FeedResult =
  | { has_feed: false }
  | { has_feed: true; last_commit: string; calibrated_prior: string; constraint: string };

function entryProjectPath(entry: string): string {
  const m = entry.match(/<!-- ARCH LOG \|[^|]+\|\s*([^>]+?)\s*-->/);
  return m?.[1] ?? '';
}

function lastMatchingEntry(content: string, projectPath?: string): string | null {
  const entries = content.split(/(?=<!-- ARCH LOG \|)/g).filter(e => e.trim());
  if (!entries.length) return null;
  if (!projectPath) return entries[entries.length - 1];
  for (let i = entries.length - 1; i >= 0; i--) {
    const p = entryProjectPath(entries[i]);
    if (p && projectPath.startsWith(p)) return entries[i];
  }
  return null;
}

function parseEntry(entry: string): FeedResult {
  if (/📝 LOG \(S\): no incidents/.test(entry)) return { has_feed: false };
  if (!/## 📝 LOG/.test(entry)) return { has_feed: false };
  if (!/- ❌/.test(entry)) return { has_feed: false };
  const failedText = entry.match(/- ❌[^:]*:\s*(.+)/)?.[1]?.trim() ?? '';
  if (/^no incidents/i.test(failedText)) return { has_feed: false };

  const calibrated_prior = entry.match(/- ✅[^:]*:\s*(.+)/)?.[1]?.trim() ?? '';
  const constraint = entry.match(/- 🔄[^:]*:\s*(.+)/)?.[1]?.trim() ?? '';
  const last_commit = entry.match(/- Commit: `([^`]+)`/)?.[1]?.trim() ?? '';

  if (!constraint) return { has_feed: false };
  return { has_feed: true, last_commit, calibrated_prior, constraint };
}

export function readFeed(projectPath: string = process.cwd()): FeedResult {
  try {
    const localPath = resolveProject('retro.md', projectPath);
    if (localPath && existsSync(localPath)) {
      const entry = lastMatchingEntry(readFileSync(localPath, 'utf8'));
      if (entry) return parseEntry(entry);
    }
    const globalPath = resolveGlobal('retro.md');
    if (existsSync(globalPath)) {
      const entry = lastMatchingEntry(readFileSync(globalPath, 'utf8'), projectPath);
      if (entry) return parseEntry(entry);
    }
    return { has_feed: false };
  } catch {
    return { has_feed: false };
  }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /home/valentin/code/arch-mcp && npx vitest run tests/tools/feed.test.ts
```

Expected: all tests PASS

- [ ] **Step 5: Add `skip_feed` to `src/schema/shift.ts`**

Replace the `ShiftState` interface `omissions` block:

```typescript
// OLD
  omissions: {
    skip_gate: number;
    skip_anchor: number;
    skip_solo: number;
    skip_log: number;
    undeclared_read: number;
    scope_creep: number;
  };
```

With:

```typescript
// NEW
  omissions: {
    skip_feed: number;
    skip_gate: number;
    skip_anchor: number;
    skip_solo: number;
    skip_log: number;
    undeclared_read: number;
    scope_creep: number;
  };
```

Replace the `DEFAULT_SHIFT_STATE.omissions` block:

```typescript
// OLD
  omissions: {
    skip_gate: 0,
    skip_anchor: 0,
    skip_solo: 0,
    skip_log: 0,
    undeclared_read: 0,
    scope_creep: 0,
  },
```

With:

```typescript
// NEW
  omissions: {
    skip_feed: 0,
    skip_gate: 0,
    skip_anchor: 0,
    skip_solo: 0,
    skip_log: 0,
    undeclared_read: 0,
    scope_creep: 0,
  },
```

Replace the `ShiftStateSchema` omissions object:

```typescript
// OLD
  omissions: z.object({
    skip_gate: z.number(),
    skip_anchor: z.number(),
    skip_solo: z.number(),
    skip_log: z.number(),
    undeclared_read: z.number(),
    scope_creep: z.number(),
  }),
```

With:

```typescript
// NEW
  omissions: z.object({
    skip_feed: z.number(),
    skip_gate: z.number(),
    skip_anchor: z.number(),
    skip_solo: z.number(),
    skip_log: z.number(),
    undeclared_read: z.number(),
    scope_creep: z.number(),
  }),
```

- [ ] **Step 6: Register `arch_feed_read` in `src/index.ts` and bump version**

Change the McpServer constructor version:

```typescript
// OLD
const server = new McpServer({ name: 'arch-mcp', version: '1.0.0' });
```

```typescript
// NEW
const server = new McpServer({ name: 'arch-mcp', version: '1.1.0' });
```

Add the import at the top of the file (after existing imports):

```typescript
import { readFeed } from './tools/feed.js';
```

Add the tool registration after the existing `arch_version` tool registration:

```typescript
server.tool('arch_feed_read', { project_path: z.string().optional() }, async ({ project_path }) => {
  try { return ok(readFeed(project_path)); }
  catch (e) { return err(String(e)); }
});
```

- [ ] **Step 7: Bump version in `package.json`**

Change `"version": "1.0.0"` to `"version": "1.1.0"`.

- [ ] **Step 8: Run the full test suite**

```bash
cd /home/valentin/code/arch-mcp && npm test
```

Expected: all 33 tests PASS (25 existing + 8 new feed tests)

- [ ] **Step 9: Commit**

```bash
cd /home/valentin/code/arch-mcp
git add src/tools/feed.ts tests/tools/feed.test.ts src/schema/shift.ts src/index.ts package.json
git commit -m "feat: add arch_feed_read tool and skip_feed omission key (v1.1.0)"
```

- [ ] **Step 10: Publish to npm**

Build first:

```bash
cd /home/valentin/code/arch-mcp && npm run build
```

Then ask the human to run:

```
npm publish --access public --otp=<OTP>
```

from `/home/valentin/code/arch-mcp`. Wait for the human to confirm `npm view @valentinlineiro/arch-mcp version` returns `1.1.0` before proceeding.

---

### Task 2: arch-protocol — `on-stop.sh` Ghost Constraint fix + scenario test

**Repo:** `/home/valentin/code/arch-protocol`

**Files:**
- Modify: `plugins/arch-protocol/scripts/on-stop.sh`
- Create: `tests/feed-ghost-constraint.md`

**Interfaces:**
- Consumes: nothing from Task 1 (independent)
- Produces: retro.md now includes clean S-task entries; `arch_feed_read` from Task 1 reads them

- [ ] **Step 1: Update `plugins/arch-protocol/scripts/on-stop.sh`**

The current script extracts only `## 📝 LOG (ARCH Kaizen)` blocks. Add S-task clean LOG capture.

Replace the section from `# Extract LOG block:` to `[ -z "$LOG_BLOCK" ] && exit 0` with:

```bash
# Extract full LOG block: from header until the next ## section or end of content
LOG_BLOCK=$(echo "$RESPONSE" | awk '
    /## 📝 LOG \(ARCH Kaizen\)/ { found=1 }
    found && /^## / && !/ARCH Kaizen/ { found=0 }
    found { print }
')

# If no full block, look for clean S-task LOG line
if [ -z "$LOG_BLOCK" ]; then
    LOG_BLOCK=$(echo "$RESPONSE" | grep '📝 LOG (S): no incidents' | tail -1)
fi

[ -z "$LOG_BLOCK" ] && exit 0
```

- [ ] **Step 2: Verify on-stop.sh is valid bash**

```bash
bash -n /home/valentin/code/arch-protocol/plugins/arch-protocol/scripts/on-stop.sh
```

Expected: no output (no syntax errors)

- [ ] **Step 3: Create `tests/feed-ghost-constraint.md`**

```markdown
# Scenario: FEED ghost constraint prevention

## Rationale
Verifies that a clean S-task LOG clears a previously carried constraint — preventing the Ghost Constraint loop.
After an M-task incident writes a constraint to retro.md, a subsequent clean S-task must write to retro.md
so that FEED reads the clean entry and returns `has_feed: false`. Without the `on-stop.sh` fix, the
S-task LOG line was never persisted and the constraint would carry forward indefinitely.

## Prompt
Here is the session context:

Previous task: An M task wrote this to retro.md:
<!-- ARCH LOG | 2026-06-23 15:42 | /proj -->
## 📝 LOG (ARCH Kaizen)
- ✅ What assumption did you make: Assumed the API was sync
- ❌ What failed: API requires await
  🤔 Why #1: didn't read the docs
- 🔄 What you'd do differently: Always check async signature
- Commit: `fix: await the call`

Now the following S-task just completed with no incidents. Run LOG for it.

## Expected markers
- [ ] `"📝 LOG (S): no incidents"` — clean S-task log line is produced
- [ ] `"commit:"` — commit message is included in the S log line

## Anti-markers
- [ ] `"## 📝 LOG (ARCH Kaizen)"` — full block means S compression did not fire

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 4: Commit**

```bash
cd /home/valentin/code/arch-protocol
git add plugins/arch-protocol/scripts/on-stop.sh tests/feed-ghost-constraint.md
git commit -m "fix(on-stop): capture clean S-task LOG lines to prevent ghost constraints"
```

---

### Task 3: arch-protocol — SKILL.md + PROTOCOL.md + plugin.json + feed-carry-forward test

**Depends on:** Task 1 npm publish (1.1.0 must be available on npm)

**Repo:** `/home/valentin/code/arch-protocol`

**Files:**
- Modify: `plugins/arch-protocol/skills/arch-protocol/SKILL.md`
- Modify: `plugins/arch-protocol/PROTOCOL.md`
- Modify: `plugins/arch-protocol/.claude-plugin/plugin.json`
- Create: `tests/feed-carry-forward.md`

**Interfaces:**
- Consumes: `arch_feed_read` from Task 1 (MCP tool, prefix `mcp__plugin_arch-protocol_arch-mcp__arch_feed_read`)

- [ ] **Step 1: Update `plugin.json`**

In `plugins/arch-protocol/.claude-plugin/plugin.json`:

```json
// OLD
{
  "name": "arch-protocol",
  "version": "2.0.1",
  ...
  "mcpServers": {
    "arch-mcp": {
      "command": "npx",
      "args": ["-y", "@valentinlineiro/arch-mcp@1.0.0"]
    }
  }
}
```

```json
// NEW
{
  "name": "arch-protocol",
  "version": "2.1.0",
  ...
  "mcpServers": {
    "arch-mcp": {
      "command": "npx",
      "args": ["-y", "@valentinlineiro/arch-mcp@1.1.0"]
    }
  }
}
```

- [ ] **Step 2: Fix the comment in `SKILL.md`**

Replace line 6:

```
<!-- Claude Code adapter. Source of truth: PROTOCOL.md -->
```

With:

```
<!-- Claude Code adapter. Adapted from platform-agnostic specification in PROTOCOL.md -->
```

- [ ] **Step 3: Replace the Quick Reference table in `SKILL.md`**

Replace:

```markdown
| Step | Name | One-liner |
|------|------|-----------|
| 1 | GATE | Objective + Context + Constraints — all three, or stop |
| 2 | ANCHOR | Check `git status --short` every time |
| 3 | ATOM | Classify S/M/L — S compresses GATE+PULL+SOLO into one line |
| 4 | PULL | Declare exactly what context you'll use |
| 5 | SOLO | One logical change only |
| 6 | EYES | PULL + SOLO declared vs. `git diff ANCHOR_HASH` — surface any divergence |
| 7 | LOG | Retrospective block — always, no exceptions |
```

With:

```markdown
| Step | Name | One-liner |
|------|------|-----------|
| 1 | FEED | Surface calibrated priors + constraints from the last LOG — or skip cleanly |
| 2 | GATE | Objective + Context + Constraints — all three, or stop |
| 3 | ANCHOR | Check `git status --short` every time |
| 4 | ATOM | Classify S/M/L — S compresses GATE+PULL+SOLO into one line |
| 5 | PULL | Declare exactly what context you'll use |
| 6 | SOLO | One logical change only |
| 7 | EYES | PULL + SOLO declared vs. `git diff ANCHOR_HASH` — surface any divergence |
| 8 | LOG | Retrospective block — always, no exceptions |
```

- [ ] **Step 4: Add FEED step to `SKILL.md` Workflow section**

Insert the following block immediately BEFORE the `**1. GATE**` line (after the evolve-check paragraph, before GATE):

```markdown
**1. FEED** — Call `mcp__plugin_arch-protocol_arch-mcp__arch_feed_read` with `{ "project_path": "<cwd>" }`.

If `has_feed: true`:
```
🔄 FEED: Carry-forward from previous task (commit: <last_commit>)
- 💡 Calibrated Prior: <calibrated_prior>
- 🎯 Constraint: <constraint>
```
Prepend `<constraint>` to the Constraints field in GATE. If the user overrides, note the override in GATE — do not drop it silently.

If `has_feed: false` (or `has_feed: false` on an S task):
```
✓ FEED: no constraints carried forward.
```

**S-task compression:** If the task is S and `has_feed: false`: `✓ FEED (S): no constraints carried forward.` If `has_feed: true`, run FEED at full length regardless of task size — carried constraints never compress.

```

- [ ] **Step 5: Renumber existing steps in `SKILL.md`**

Make these exact replacements (in order, searching for the exact string):

| Old string | New string |
|---|---|
| `**1. GATE**` | `**2. GATE**` |
| `**2. ANCHOR**` | `**3. ANCHOR**` |
| `**3. ATOM**` | `**4. ATOM**` |
| `Run all 7 steps, but compress GATE + PULL + SOLO` | `Run all 8 steps, but compress GATE + PULL + SOLO` |
| `Run all 7 steps at full length.` | `Run all 8 steps at full length.` |
| `see steps 6–7.` | `see steps 7–8.` |
| `**4. PULL**` | `**5. PULL**` |
| `**5. SOLO**` | `**6. SOLO**` |
| `**6. EYES**` | `**7. EYES**` |
| `**7. LOG**` | `**8. LOG**` |
| `**ANCHOR (step 2):**` | `**ANCHOR (step 3):**` |
| `**PULL (step 4):**` | `**PULL (step 5):**` |
| `M/L tasks (step 3 above)` | `M/L tasks (step 8 above — LOG step 3)` |

- [ ] **Step 6: Add `skip_feed` to SHIFT vocabulary table in `SKILL.md`**

In the SHIFT section, find the controlled vocabulary table and add a row at the top:

```markdown
| `skip_feed` | FEED was skipped or `arch_feed_read` was not called |
```

Insert it as the first data row (before `skip_gate`).

- [ ] **Step 7: Add `skip_feed` to the schema reference in `SKILL.md`**

In the SHIFT section, find the schema JSON block:

```json
  "omissions": {
    "skip_gate": 0,
```

Replace with:

```json
  "omissions": {
    "skip_feed": 0,
    "skip_gate": 0,
```

- [ ] **Step 8: Update `PROTOCOL.md` with same structural changes**

PROTOCOL.md uses abstract notation (no MCP tool names). Apply these changes:

**a) Replace the Quick Reference table** — same 8-row version as SKILL.md Step 3 above, without MCP-specific content.

**b) Add FEED step** — insert before `**1. GATE**`:

```markdown
**1. FEED** — Call `TOOL: arch_feed_read` with `{ "project_path": "<cwd>" }`.

If `has_feed: true`:
```
🔄 FEED: Carry-forward from previous task (commit: <last_commit>)
- 💡 Calibrated Prior: <calibrated_prior>
- 🎯 Constraint: <constraint>
```
Prepend `<constraint>` to the Constraints field in GATE. If the user overrides, note the override.

If `has_feed: false`:
```
✓ FEED: no constraints carried forward.
```

**S-task compression:** If the task is S and `has_feed: false`: `✓ FEED (S): no constraints carried forward.` If `has_feed: true`, FEED runs at full length.

```

**c) Apply the same step renumbering** as SKILL.md Step 5 above (same table of old→new strings).

**d) Add `skip_feed` to vocabulary table and schema** — same as SKILL.md Steps 6–7 above.

- [ ] **Step 9: Create `tests/feed-carry-forward.md`**

```markdown
# Scenario: FEED carry-forward from M task incident

## Rationale
Verifies that FEED fires before GATE and surfaces a carried constraint from the previous task's LOG.
The constraint from the last M-task ❌/🔄 fields must appear in the FEED block before GATE runs.
The carried constraint must also appear in GATE's Constraints field.

## Prompt
Here is the session context:

Previous task logged this to retro.md:
<!-- ARCH LOG | 2026-06-23 15:42 | /proj -->
## 📝 LOG (ARCH Kaizen)
- ✅ What assumption did you make: Assumed the config was loaded before the handler ran
- ❌ What failed or caused friction: Config not yet loaded — handler read undefined values
  🤔 Why #1: initialization order not checked
- 🔄 What you'd do differently next time: Always verify config is initialized before calling handlers
- Commit: `fix: ensure config loads before handler`

Now I want to add a new feature: add a /health endpoint to the Express app.

## Expected markers
- [ ] `"🔄 FEED:"` — FEED step fired and surfaced the carry-forward block
- [ ] `"Calibrated Prior:"` — assumption field is present
- [ ] `"Constraint:"` — constraint field is present
- [ ] `"Always verify config is initialized"` — exact constraint text carried forward

## Anti-markers
- [ ] `"To make sure I understand correctly"` — GATE must not fire before FEED

## Pass condition
All markers present AND no anti-marker present.
```

- [ ] **Step 10: Run the test scenarios manually (optional verification)**

The scenario tests are human-run. To verify:
1. Activate the updated plugin (`/plugin install arch-protocol@arch-protocol` or `/reload-plugins`)
2. Run the prompt from `tests/feed-carry-forward.md` and check for the expected markers
3. Run the prompt from `tests/feed-ghost-constraint.md` and check for the expected markers

- [ ] **Step 11: Commit**

```bash
cd /home/valentin/code/arch-protocol
git add plugins/arch-protocol/skills/arch-protocol/SKILL.md \
        plugins/arch-protocol/PROTOCOL.md \
        plugins/arch-protocol/.claude-plugin/plugin.json \
        tests/feed-carry-forward.md
git commit -m "feat: add FEED step (step 1 of 8), renumber protocol, bump to 2.1.0"
```

- [ ] **Step 12: Push**

```bash
cd /home/valentin/code/arch-protocol && git push
```
