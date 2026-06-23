# ARCH MCP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a TypeScript MCP server that exposes ARCH protocol state operations as seven structured tools, replacing inline shell commands in SKILL.md.

**Architecture:** A schema layer owns the shared data contracts (ShiftState, soloMarkerName). A lib layer owns all path resolution and Bash execution. Seven tool modules implement the business logic. A single entry point (index.ts) registers all tools with the MCP SDK and connects to stdio transport.

**Tech Stack:** Node.js 20+, TypeScript 5 (ESM), @modelcontextprotocol/sdk ^1.0.0, zod ^3.0.0, Vitest 2

## Global Constraints

- Repo lives at `~/code/arch-mcp/` (sibling of `~/code/arch-protocol/`)
- Package name: `@valentinlineiro/arch-mcp`, version: `0.1.0`
- `"type": "module"` — ESM only. All source imports use `.js` extension even when resolving `.ts` files
- Every write to any `~/.arch/` path must call `mkdirSync(dirname(path), { recursive: true })` first
- All tools return `{ success: true, data: T }` on success; `{ success: false, error: string }` with `isError: true` on failure
- No protocol logic in the server (thresholds, PUSHBACK, escalation rules live in SKILL.md)
- No network calls, no Windows support (WSL is fine, `os.homedir()` resolves correctly)
- ARCH protocol is active in this repo from Task 1 onward — run ARCH for every subsequent task

---

### Task 1: Repo scaffold + ARCH init

**Files:**
- Create: `~/code/arch-mcp/package.json`
- Create: `~/code/arch-mcp/tsconfig.json`
- Create: `~/code/arch-mcp/vitest.config.ts`
- Create: `~/code/arch-mcp/.gitignore`

**Interfaces:**
- Produces: a compilable, testable TypeScript project that Claude Code can load as an MCP server

- [ ] **Step 1: Create the repo directory and initialize git**

```bash
mkdir ~/code/arch-mcp
cd ~/code/arch-mcp
git init
git commit --allow-empty -m "chore: initial commit"
```

- [ ] **Step 2: Run ARCH init**

```bash
bash "$(find ~/.claude/plugins -name "arch-init.sh" | head -1)"
```

Expected output: confirms `.arch/` created, `CLAUDE.md` updated, `~/.arch/retro.md` reachable.

- [ ] **Step 3: Write package.json**

```json
{
  "name": "@valentinlineiro/arch-mcp",
  "version": "0.1.0",
  "description": "MCP server for ARCH protocol state operations",
  "type": "module",
  "main": "dist/index.js",
  "bin": {
    "arch-mcp": "dist/index.js"
  },
  "scripts": {
    "build": "tsc",
    "test": "vitest run",
    "start": "node dist/index.js"
  },
  "dependencies": {
    "@modelcontextprotocol/sdk": "^1.0.0",
    "zod": "^3.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "vitest": "^2.0.0"
  }
}
```

- [ ] **Step 4: Write tsconfig.json**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "outDir": "dist",
    "rootDir": "src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "declaration": true
  },
  "include": ["src"]
}
```

- [ ] **Step 5: Write vitest.config.ts**

```typescript
import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    globals: true,
  },
});
```

- [ ] **Step 6: Write .gitignore**

```
node_modules/
dist/
.arch/
```

- [ ] **Step 7: Install dependencies**

```bash
npm install
```

Expected: `node_modules/` created, `package-lock.json` generated, no errors.

- [ ] **Step 8: Create directory structure**

```bash
mkdir -p src/tools src/lib src/schema tests/tools tests/lib tests/schema
```

- [ ] **Step 9: Verify TypeScript compiles an empty entry point**

Create `src/index.ts`:
```typescript
export {};
```

Run: `npm run build`
Expected: `dist/index.js` created, no errors.

- [ ] **Step 10: Commit**

```bash
git add package.json tsconfig.json vitest.config.ts .gitignore src/ tests/
git commit -m "chore: scaffold arch-mcp project with ARCH init"
```

---

### Task 2: Schema layer

**Files:**
- Create: `src/schema/shift.ts`
- Create: `src/schema/conventions.ts`
- Test: `tests/schema/shift.test.ts`

**Interfaces:**
- Produces:
  - `ShiftState` (TypeScript interface)
  - `DEFAULT_SHIFT_STATE: ShiftState`
  - `ShiftStateSchema` (zod schema — used by index.ts for `arch_shift_write` input validation)
  - `soloMarkerName(hash: string): string`

- [ ] **Step 1: Write the failing test**

Create `tests/schema/shift.test.ts`:

```typescript
import { describe, it, expect } from 'vitest';
import { DEFAULT_SHIFT_STATE } from '../../src/schema/shift.js';
import { soloMarkerName } from '../../src/schema/conventions.js';

describe('DEFAULT_SHIFT_STATE', () => {
  it('has all omission keys set to 0', () => {
    const keys = ['skip_gate', 'skip_anchor', 'skip_solo', 'skip_log', 'undeclared_read', 'scope_creep'];
    for (const k of keys) {
      expect(DEFAULT_SHIFT_STATE.omissions[k as keyof typeof DEFAULT_SHIFT_STATE.omissions]).toBe(0);
    }
  });

  it('has session_task_count set to 0', () => {
    expect(DEFAULT_SHIFT_STATE.session_task_count).toBe(0);
  });

  it('has log_count_at_last_evolve set to 0', () => {
    expect(DEFAULT_SHIFT_STATE.log_count_at_last_evolve).toBe(0);
  });

  it('has last_omission_cleared set to null', () => {
    expect(DEFAULT_SHIFT_STATE.last_omission_cleared).toBeNull();
  });
});

describe('soloMarkerName', () => {
  it('returns solo_declared_<hash>', () => {
    expect(soloMarkerName('abc123')).toBe('solo_declared_abc123');
  });

  it('handles full SHA hashes', () => {
    const hash = 'e3a01096c357ef2d04b4dbfb8ddfe5c21d20a45b';
    expect(soloMarkerName(hash)).toBe(`solo_declared_${hash}`);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npm test -- tests/schema/shift.test.ts
```

Expected: FAIL — modules not found.

- [ ] **Step 3: Write src/schema/shift.ts**

```typescript
import { z } from 'zod';

export interface ShiftState {
  omissions: {
    skip_gate: number;
    skip_anchor: number;
    skip_solo: number;
    skip_log: number;
    undeclared_read: number;
    scope_creep: number;
  };
  last_omission_cleared: string | null;
  log_count_at_last_evolve: number;
  session_task_count: number;
}

export const DEFAULT_SHIFT_STATE: ShiftState = {
  omissions: {
    skip_gate: 0,
    skip_anchor: 0,
    skip_solo: 0,
    skip_log: 0,
    undeclared_read: 0,
    scope_creep: 0,
  },
  last_omission_cleared: null,
  log_count_at_last_evolve: 0,
  session_task_count: 0,
};

export const ShiftStateSchema = z.object({
  omissions: z.object({
    skip_gate: z.number(),
    skip_anchor: z.number(),
    skip_solo: z.number(),
    skip_log: z.number(),
    undeclared_read: z.number(),
    scope_creep: z.number(),
  }),
  last_omission_cleared: z.string().nullable(),
  log_count_at_last_evolve: z.number(),
  session_task_count: z.number(),
});
```

- [ ] **Step 4: Write src/schema/conventions.ts**

```typescript
export function soloMarkerName(hash: string): string {
  return `solo_declared_${hash}`;
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
npm test -- tests/schema/shift.test.ts
```

Expected: PASS — 6 tests.

- [ ] **Step 6: Commit**

```bash
git add src/schema/ tests/schema/
git commit -m "feat: add schema layer (ShiftState, ShiftStateSchema, soloMarkerName)"
```

---

### Task 3: lib/paths.ts

**Files:**
- Create: `src/lib/paths.ts`
- Test: `tests/lib/paths.test.ts`

**Interfaces:**
- Produces:
  - `resolveGlobal(filename: string): string` — `~/.arch/<filename>`
  - `resolveProject(filename: string, cwd?: string): string | null` — `.arch/<filename>` relative to cwd, or `null`

Note: `resolveProject` accepts an optional `cwd` parameter (defaults to `process.cwd()`) to enable testing without process mocking.

- [ ] **Step 1: Write the failing test**

Create `tests/lib/paths.test.ts`:

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { mkdirSync, rmSync } from 'fs';
import { join } from 'path';
import { tmpdir, homedir } from 'os';
import { resolveGlobal, resolveProject } from '../../src/lib/paths.js';

describe('resolveGlobal', () => {
  it('returns path under ~/.arch/', () => {
    expect(resolveGlobal('shift.json')).toBe(join(homedir(), '.arch', 'shift.json'));
  });
});

describe('resolveProject', () => {
  let tmpDir: string;

  beforeEach(() => {
    tmpDir = join(tmpdir(), `arch-paths-test-${Date.now()}`);
    mkdirSync(tmpDir, { recursive: true });
  });

  afterEach(() => {
    rmSync(tmpDir, { recursive: true, force: true });
  });

  it('returns null when .arch/ does not exist', () => {
    expect(resolveProject('retro.md', tmpDir)).toBeNull();
  });

  it('returns .arch/<filename> when .arch/ exists', () => {
    mkdirSync(join(tmpDir, '.arch'));
    expect(resolveProject('retro.md', tmpDir)).toBe(join(tmpDir, '.arch', 'retro.md'));
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npm test -- tests/lib/paths.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Write src/lib/paths.ts**

```typescript
import { homedir } from 'os';
import { existsSync } from 'fs';
import { join, resolve } from 'path';

export function resolveGlobal(filename: string): string {
  return join(homedir(), '.arch', filename);
}

export function resolveProject(filename: string, cwd: string = process.cwd()): string | null {
  const projectArch = resolve(cwd, '.arch');
  if (!existsSync(projectArch)) return null;
  return join(projectArch, filename);
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npm test -- tests/lib/paths.test.ts
```

Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/lib/paths.ts tests/lib/paths.test.ts
git commit -m "feat: add lib/paths.ts with resolveGlobal and resolveProject"
```

---

### Task 4: tools/shift.ts + lib/exec.ts

**Files:**
- Create: `src/lib/exec.ts`
- Create: `src/tools/shift.ts`
- Test: `tests/tools/shift.test.ts`

**Interfaces:**
- Consumes: `resolveGlobal` from `../lib/paths.js`; `ShiftState`, `DEFAULT_SHIFT_STATE` from `../schema/shift.js`
- Produces:
  - `run(cmd: string, cwd?: string): { stdout: string; stderr: string }` (from exec.ts)
  - `ExecError` class (from exec.ts)
  - `readShift(): ShiftState`
  - `writeShift(state: ShiftState): void`
  - `sessionIncrement(): number` — returns new count

exec.ts has no dedicated unit tests (it wraps system calls); it is exercised by the anchor tests in Task 5.

- [ ] **Step 1: Write the failing test**

Create `tests/tools/shift.test.ts`:

```typescript
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { mkdirSync, rmSync, existsSync, writeFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

const TEST_DIR = join(tmpdir(), 'arch-mcp-shift-test');

vi.mock('../../src/lib/paths.js', () => ({
  resolveGlobal: (filename: string) => join(TEST_DIR, filename),
  resolveProject: (_filename: string, _cwd?: string) => null,
}));

const { readShift, writeShift, sessionIncrement } = await import('../../src/tools/shift.js');

describe('readShift', () => {
  beforeEach(() => mkdirSync(TEST_DIR, { recursive: true }));
  afterEach(() => rmSync(TEST_DIR, { recursive: true, force: true }));

  it('creates default shift.json when file is absent', () => {
    const state = readShift();
    expect(state.session_task_count).toBe(0);
    expect(state.omissions.skip_gate).toBe(0);
    expect(existsSync(join(TEST_DIR, 'shift.json'))).toBe(true);
  });

  it('backfills missing fields from an old file lacking session_task_count', () => {
    const old = {
      omissions: { skip_gate: 2, skip_anchor: 0, skip_solo: 0, skip_log: 0, undeclared_read: 0, scope_creep: 0 },
      last_omission_cleared: null,
      log_count_at_last_evolve: 3,
    };
    writeFileSync(join(TEST_DIR, 'shift.json'), JSON.stringify(old));
    const state = readShift();
    expect(state.session_task_count).toBe(0);
    expect(state.omissions.skip_gate).toBe(2);
    expect(state.log_count_at_last_evolve).toBe(3);
  });
});

describe('writeShift + readShift roundtrip', () => {
  beforeEach(() => mkdirSync(TEST_DIR, { recursive: true }));
  afterEach(() => rmSync(TEST_DIR, { recursive: true, force: true }));

  it('persists and restores state correctly', () => {
    const state = readShift();
    state.omissions.skip_gate = 3;
    writeShift(state);
    const back = readShift();
    expect(back.omissions.skip_gate).toBe(3);
  });
});

describe('sessionIncrement', () => {
  beforeEach(() => mkdirSync(TEST_DIR, { recursive: true }));
  afterEach(() => rmSync(TEST_DIR, { recursive: true, force: true }));

  it('increments session_task_count from 0 to 1', () => {
    expect(sessionIncrement()).toBe(1);
  });

  it('increments again on second call', () => {
    sessionIncrement();
    expect(sessionIncrement()).toBe(2);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npm test -- tests/tools/shift.test.ts
```

Expected: FAIL — modules not found.

- [ ] **Step 3: Write src/lib/exec.ts**

```typescript
import { execSync } from 'child_process';

export class ExecError extends Error {
  constructor(
    public readonly cmd: string,
    public readonly code: number,
    public readonly stderr: string,
  ) {
    super(`Command failed (exit ${code}): ${cmd}\n${stderr}`);
    this.name = 'ExecError';
  }
}

export function run(cmd: string, cwd?: string): { stdout: string; stderr: string } {
  try {
    const stdout = execSync(cmd, {
      cwd,
      encoding: 'utf8',
      stdio: ['ignore', 'pipe', 'pipe'],
    });
    return { stdout: (stdout as string).trim(), stderr: '' };
  } catch (e: unknown) {
    const err = e as { status?: number; stderr?: Buffer };
    throw new ExecError(cmd, err.status ?? 1, err.stderr?.toString().trim() ?? '');
  }
}
```

- [ ] **Step 4: Write src/tools/shift.ts**

```typescript
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { dirname } from 'path';
import { resolveGlobal } from '../lib/paths.js';
import { ShiftState, DEFAULT_SHIFT_STATE } from '../schema/shift.js';

export function readShift(): ShiftState {
  const shiftPath = resolveGlobal('shift.json');
  mkdirSync(dirname(shiftPath), { recursive: true });
  if (!existsSync(shiftPath)) {
    const fresh = { ...DEFAULT_SHIFT_STATE, omissions: { ...DEFAULT_SHIFT_STATE.omissions } };
    writeFileSync(shiftPath, JSON.stringify(fresh, null, 2), 'utf8');
    return fresh;
  }
  const raw = JSON.parse(readFileSync(shiftPath, 'utf8')) as Partial<ShiftState>;
  return {
    ...DEFAULT_SHIFT_STATE,
    ...raw,
    omissions: { ...DEFAULT_SHIFT_STATE.omissions, ...(raw.omissions ?? {}) },
  };
}

export function writeShift(state: ShiftState): void {
  const shiftPath = resolveGlobal('shift.json');
  mkdirSync(dirname(shiftPath), { recursive: true });
  writeFileSync(shiftPath, JSON.stringify(state, null, 2), 'utf8');
}

export function sessionIncrement(): number {
  const state = readShift();
  state.session_task_count += 1;
  writeShift(state);
  return state.session_task_count;
}
```

- [ ] **Step 5: Run test to verify it passes**

```bash
npm test -- tests/tools/shift.test.ts
```

Expected: PASS — 6 tests.

Note: `vi.mock` is hoisted above all imports by Vitest, so the mock is active when `shift.ts` is first loaded. If you see import resolution errors, verify `vitest.config.ts` has `globals: true`.

- [ ] **Step 6: Commit**

```bash
git add src/lib/exec.ts src/tools/shift.ts tests/tools/shift.test.ts
git commit -m "feat: add shift tools (shift_read, shift_write, session_increment) and exec.ts"
```

---

### Task 5: tools/anchor.ts — arch_anchor

**Files:**
- Create: `src/tools/anchor.ts`
- Test: `tests/tools/anchor.test.ts`

**Interfaces:**
- Consumes: `resolveGlobal` from `../lib/paths.js`; `run` from `../lib/exec.js`
- Produces:
  - `AnchorResult = { dirty: boolean; hash: string; uncommitted_files: string[] }`
  - `runAnchor(): Promise<AnchorResult>`

- [ ] **Step 1: Write the failing test**

Create `tests/tools/anchor.test.ts`:

```typescript
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { mkdirSync, rmSync, writeFileSync, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { execSync } from 'child_process';

const TEST_ARCH_DIR = join(tmpdir(), 'arch-mcp-anchor-test');

vi.mock('../../src/lib/paths.js', () => ({
  resolveGlobal: (filename: string) => join(TEST_ARCH_DIR, filename),
  resolveProject: () => null,
}));

const { runAnchor } = await import('../../src/tools/anchor.js');

function makeGitRepo(): string {
  const dir = join(tmpdir(), `arch-anchor-repo-${Date.now()}`);
  mkdirSync(dir, { recursive: true });
  execSync('git init', { cwd: dir });
  execSync('git config user.email "test@test.com"', { cwd: dir });
  execSync('git config user.name "Test"', { cwd: dir });
  execSync('git commit --allow-empty -m "init"', { cwd: dir });
  return dir;
}

describe('runAnchor', () => {
  let repoDir: string;
  const originalCwd = process.cwd();

  beforeEach(() => {
    mkdirSync(TEST_ARCH_DIR, { recursive: true });
    repoDir = makeGitRepo();
    process.chdir(repoDir);
  });

  afterEach(() => {
    process.chdir(originalCwd);
    rmSync(TEST_ARCH_DIR, { recursive: true, force: true });
    rmSync(repoDir, { recursive: true, force: true });
  });

  it('returns dirty=false and a 40-char hash for a clean repo', async () => {
    const result = await runAnchor();
    expect(result.dirty).toBe(false);
    expect(result.hash).toMatch(/^[0-9a-f]{40}$/);
    expect(result.uncommitted_files).toHaveLength(0);
  });

  it('returns dirty=true and lists files for a dirty repo', async () => {
    writeFileSync(join(repoDir, 'foo.txt'), 'hello');
    const result = await runAnchor();
    expect(result.dirty).toBe(true);
    expect(result.uncommitted_files.some(f => f.includes('foo.txt'))).toBe(true);
  });

  it('writes anchor_state to the arch dir', async () => {
    await runAnchor();
    const anchorPath = join(TEST_ARCH_DIR, 'anchor_state');
    expect(existsSync(anchorPath)).toBe(true);
    const content = readFileSync(anchorPath, 'utf8');
    expect(content).toContain('dirty=false');
    expect(content).toMatch(/hash=[0-9a-f]{40}/);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npm test -- tests/tools/anchor.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Write src/tools/anchor.ts**

```typescript
import { writeFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { resolveGlobal } from '../lib/paths.js';
import { run } from '../lib/exec.js';

export interface AnchorResult {
  dirty: boolean;
  hash: string;
  uncommitted_files: string[];
}

export async function runAnchor(): Promise<AnchorResult> {
  const statusOutput = run('git status --short').stdout;
  const uncommitted_files = statusOutput
    ? statusOutput.split('\n').map(l => l.trim()).filter(Boolean)
    : [];
  const dirty = uncommitted_files.length > 0;
  const hash = run('git rev-parse HEAD').stdout;

  const anchorStatePath = resolveGlobal('anchor_state');
  mkdirSync(dirname(anchorStatePath), { recursive: true });
  writeFileSync(anchorStatePath, `dirty=${dirty}\nhash=${hash}\n`, 'utf8');

  return { dirty, hash, uncommitted_files };
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npm test -- tests/tools/anchor.test.ts
```

Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/tools/anchor.ts tests/tools/anchor.test.ts
git commit -m "feat: add arch_anchor tool"
```

---

### Task 6: tools/solo.ts — arch_solo_declare

**Files:**
- Create: `src/tools/solo.ts`
- Test: `tests/tools/solo.test.ts`

**Interfaces:**
- Consumes: `resolveGlobal` from `../lib/paths.js`; `soloMarkerName` from `../schema/conventions.js`
- Produces:
  - `SoloDeclareResult = { marker_path: string; created: true }`
  - `runSoloDeclare(hash: string): Promise<SoloDeclareResult>`

- [ ] **Step 1: Write the failing test**

Create `tests/tools/solo.test.ts`:

```typescript
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { mkdirSync, rmSync, existsSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

const TEST_DIR = join(tmpdir(), 'arch-mcp-solo-test');

vi.mock('../../src/lib/paths.js', () => ({
  resolveGlobal: (filename: string) => join(TEST_DIR, filename),
  resolveProject: () => null,
}));

const { runSoloDeclare } = await import('../../src/tools/solo.js');

describe('runSoloDeclare', () => {
  beforeEach(() => mkdirSync(TEST_DIR, { recursive: true }));
  afterEach(() => rmSync(TEST_DIR, { recursive: true, force: true }));

  it('creates the solo marker file', async () => {
    const result = await runSoloDeclare('abc123');
    expect(existsSync(result.marker_path)).toBe(true);
    expect(result.created).toBe(true);
  });

  it('marker path ends with solo_declared_<hash>', async () => {
    const result = await runSoloDeclare('deadbeef');
    expect(result.marker_path).toMatch(/solo_declared_deadbeef$/);
  });

  it('is idempotent — second call on same hash returns created: true', async () => {
    await runSoloDeclare('abc123');
    const result = await runSoloDeclare('abc123');
    expect(result.created).toBe(true);
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npm test -- tests/tools/solo.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Write src/tools/solo.ts**

```typescript
import { writeFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { resolveGlobal } from '../lib/paths.js';
import { soloMarkerName } from '../schema/conventions.js';

export interface SoloDeclareResult {
  marker_path: string;
  created: true;
}

export async function runSoloDeclare(hash: string): Promise<SoloDeclareResult> {
  const markerPath = resolveGlobal(soloMarkerName(hash));
  mkdirSync(dirname(markerPath), { recursive: true });
  writeFileSync(markerPath, '', 'utf8');
  return { marker_path: markerPath, created: true };
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npm test -- tests/tools/solo.test.ts
```

Expected: PASS — 3 tests.

- [ ] **Step 5: Commit**

```bash
git add src/tools/solo.ts tests/tools/solo.test.ts
git commit -m "feat: add arch_solo_declare tool"
```

---

### Task 7: tools/retro.ts — arch_retro_append

**Files:**
- Create: `src/tools/retro.ts`
- Test: `tests/tools/retro.test.ts`

**Interfaces:**
- Consumes: `resolveGlobal`, `resolveProject` from `../lib/paths.js`
- Produces:
  - `RetroAppendResult = { file: string; appended: true }`
  - `runRetroAppend(scope: 'global' | 'project', content: string): Promise<RetroAppendResult>`

- [ ] **Step 1: Write the failing test**

Create `tests/tools/retro.test.ts`:

```typescript
import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { mkdirSync, rmSync, readFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';

const GLOBAL_DIR = join(tmpdir(), 'arch-mcp-retro-global');
const PROJECT_DIR = join(tmpdir(), 'arch-mcp-retro-project');
let useProject = false;

vi.mock('../../src/lib/paths.js', () => ({
  resolveGlobal: (filename: string) => join(GLOBAL_DIR, filename),
  resolveProject: (filename: string) =>
    useProject ? join(PROJECT_DIR, '.arch', filename) : null,
}));

const { runRetroAppend } = await import('../../src/tools/retro.js');

describe('global scope', () => {
  beforeEach(() => { useProject = false; mkdirSync(GLOBAL_DIR, { recursive: true }); });
  afterEach(() => rmSync(GLOBAL_DIR, { recursive: true, force: true }));

  it('appends content to retro.md', async () => {
    const result = await runRetroAppend('global', '## 📝 LOG\n- test entry');
    expect(result.appended).toBe(true);
    expect(readFileSync(result.file, 'utf8')).toContain('## 📝 LOG');
  });

  it('appends multiple times without overwriting', async () => {
    await runRetroAppend('global', 'entry 1');
    await runRetroAppend('global', 'entry 2');
    const content = readFileSync(join(GLOBAL_DIR, 'retro.md'), 'utf8');
    expect(content).toContain('entry 1');
    expect(content).toContain('entry 2');
  });
});

describe('project scope', () => {
  beforeEach(() => {
    useProject = true;
    mkdirSync(join(PROJECT_DIR, '.arch'), { recursive: true });
  });
  afterEach(() => rmSync(PROJECT_DIR, { recursive: true, force: true }));

  it('writes to .arch/retro.md when scope is project', async () => {
    const result = await runRetroAppend('project', '## 📝 LOG\n- project entry');
    expect(result.file).toContain(PROJECT_DIR);
    expect(readFileSync(result.file, 'utf8')).toContain('project entry');
  });

  it('throws when scope=project but resolveProject returns null', async () => {
    useProject = false;
    await expect(runRetroAppend('project', 'x')).rejects.toThrow('No .arch/');
  });
});
```

- [ ] **Step 2: Run test to verify it fails**

```bash
npm test -- tests/tools/retro.test.ts
```

Expected: FAIL — module not found.

- [ ] **Step 3: Write src/tools/retro.ts**

```typescript
import { appendFileSync, mkdirSync } from 'fs';
import { dirname } from 'path';
import { resolveGlobal, resolveProject } from '../lib/paths.js';

export interface RetroAppendResult {
  file: string;
  appended: true;
}

export async function runRetroAppend(
  scope: 'global' | 'project',
  content: string,
): Promise<RetroAppendResult> {
  let retroPath: string;
  if (scope === 'project') {
    const projectPath = resolveProject('retro.md');
    if (projectPath === null) {
      throw new Error('No .arch/ directory found in current working directory');
    }
    retroPath = projectPath;
  } else {
    retroPath = resolveGlobal('retro.md');
  }
  mkdirSync(dirname(retroPath), { recursive: true });
  appendFileSync(retroPath, content + '\n', 'utf8');
  return { file: retroPath, appended: true };
}
```

- [ ] **Step 4: Run test to verify it passes**

```bash
npm test -- tests/tools/retro.test.ts
```

Expected: PASS — 4 tests.

- [ ] **Step 5: Commit**

```bash
git add src/tools/retro.ts tests/tools/retro.test.ts
git commit -m "feat: add arch_retro_append tool"
```

---

### Task 8: tools/version.ts — arch_version

**Files:**
- Create: `src/tools/version.ts`

**Interfaces:**
- Produces:
  - `VersionResult = { mcp_version: string; protocol_version: string | null }`
  - `runVersion(): Promise<VersionResult>`

No isolated unit test — reads `package.json` (build artifact) and a best-effort plugin path. Exercised by the integration test in Task 9.

- [ ] **Step 1: Write src/tools/version.ts**

```typescript
import { readFileSync, existsSync, readdirSync } from 'fs';
import { join } from 'path';
import { homedir } from 'os';
import { fileURLToPath } from 'url';
import { dirname } from 'path';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

export interface VersionResult {
  mcp_version: string;
  protocol_version: string | null;
}

function readMcpVersion(): string {
  const pkgPath = join(__dirname, '../../package.json');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf8')) as { version: string };
  return pkg.version;
}

function findProtocolVersion(): string | null {
  // ~/.claude/plugins/cache/arch-protocol/arch-protocol/<semver>/plugin.json
  const basePath = join(homedir(), '.claude', 'plugins', 'cache', 'arch-protocol', 'arch-protocol');
  if (!existsSync(basePath)) return null;
  try {
    const versions = readdirSync(basePath).sort().reverse();
    for (const v of versions) {
      const pluginJson = join(basePath, v, 'plugin.json');
      if (existsSync(pluginJson)) {
        const data = JSON.parse(readFileSync(pluginJson, 'utf8')) as { version?: string };
        return data.version ?? null;
      }
    }
  } catch {
    return null;
  }
  return null;
}

export async function runVersion(): Promise<VersionResult> {
  return {
    mcp_version: readMcpVersion(),
    protocol_version: findProtocolVersion(),
  };
}
```

- [ ] **Step 2: Verify it compiles**

```bash
npm run build
```

Expected: no errors. `dist/tools/version.js` present.

- [ ] **Step 3: Commit**

```bash
git add src/tools/version.ts
git commit -m "feat: add arch_version tool"
```

---

### Task 9: MCP server entry point + integration test

**Files:**
- Modify: `src/index.ts` (replace placeholder `export {}` from Task 1)
- Create: `tests/integration.test.ts`

**Interfaces:**
- Consumes: all tool modules + schema layer
- Produces: a runnable MCP server that registers 7 tools and passes the integration test

- [ ] **Step 1: Write the failing integration test**

Create `tests/integration.test.ts`:

```typescript
import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest';
import { mkdirSync, rmSync, existsSync, readFileSync } from 'fs';
import { join } from 'path';
import { tmpdir } from 'os';
import { execSync } from 'child_process';

const ARCH_DIR = join(tmpdir(), 'arch-mcp-integration');
const REPO_DIR = join(tmpdir(), `arch-mcp-integration-repo-${Date.now()}`);
const originalCwd = process.cwd();

vi.mock('../src/lib/paths.js', () => ({
  resolveGlobal: (filename: string) => join(ARCH_DIR, filename),
  resolveProject: (_filename: string, _cwd?: string) => null,
}));

const { runAnchor } = await import('../src/tools/anchor.js');
const { runSoloDeclare } = await import('../src/tools/solo.js');
const { runRetroAppend } = await import('../src/tools/retro.js');
const { sessionIncrement, readShift } = await import('../src/tools/shift.js');

beforeAll(() => {
  mkdirSync(ARCH_DIR, { recursive: true });
  mkdirSync(REPO_DIR, { recursive: true });
  execSync('git init', { cwd: REPO_DIR });
  execSync('git config user.email "test@test.com"', { cwd: REPO_DIR });
  execSync('git config user.name "Test"', { cwd: REPO_DIR });
  execSync('git commit --allow-empty -m "init"', { cwd: REPO_DIR });
  process.chdir(REPO_DIR);
});

afterAll(() => {
  process.chdir(originalCwd);
  rmSync(ARCH_DIR, { recursive: true, force: true });
  rmSync(REPO_DIR, { recursive: true, force: true });
});

describe('full ARCH task flow', () => {
  it('anchor → solo_declare → retro_append → session_increment → shift_read', async () => {
    const anchor = await runAnchor();
    expect(anchor.dirty).toBe(false);
    expect(anchor.hash).toMatch(/^[0-9a-f]{40}$/);

    const solo = await runSoloDeclare(anchor.hash);
    expect(existsSync(solo.marker_path)).toBe(true);
    expect(solo.marker_path).toContain(`solo_declared_${anchor.hash}`);

    const logContent = `## 📝 LOG (ARCH Kaizen)\n- ✅ integration test\n- Commit: \`test: verify full flow\``;
    const retro = await runRetroAppend('global', logContent);
    expect(retro.appended).toBe(true);
    expect(readFileSync(retro.file, 'utf8')).toContain('integration test');

    const count = sessionIncrement();
    expect(count).toBe(1);

    const shift = readShift();
    expect(shift.session_task_count).toBe(1);
  });
});
```

- [ ] **Step 2: Run integration test to verify it fails**

```bash
npm test -- tests/integration.test.ts
```

Expected: FAIL — the test imports work but the full flow has not been wired yet (or tools fail without a real git repo). Confirm the failure is a logic error, not a broken import.

- [ ] **Step 3: Write src/index.ts**

```typescript
#!/usr/bin/env node
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { z } from 'zod';
import { runAnchor } from './tools/anchor.js';
import { readShift, writeShift, sessionIncrement } from './tools/shift.js';
import { runRetroAppend } from './tools/retro.js';
import { runSoloDeclare } from './tools/solo.js';
import { runVersion } from './tools/version.js';
import { ShiftStateSchema } from './schema/shift.js';

function ok<T>(data: T) {
  return { content: [{ type: 'text' as const, text: JSON.stringify({ success: true, data }) }] };
}

function err(message: string) {
  return {
    content: [{ type: 'text' as const, text: JSON.stringify({ success: false, error: message }) }],
    isError: true as const,
  };
}

const server = new McpServer({ name: 'arch-mcp', version: '0.1.0' });

server.tool('arch_anchor', {}, async () => {
  try { return ok(await runAnchor()); }
  catch (e) { return err(String(e)); }
});

server.tool('arch_shift_read', {}, async () => {
  try { return ok(readShift()); }
  catch (e) { return err(String(e)); }
});

server.tool('arch_shift_write', { state: ShiftStateSchema }, async ({ state }) => {
  try { writeShift(state); return ok({ written: true }); }
  catch (e) { return err(String(e)); }
});

server.tool('arch_session_increment', {}, async () => {
  try { return ok({ session_task_count: sessionIncrement() }); }
  catch (e) { return err(String(e)); }
});

server.tool('arch_retro_append', {
  scope: z.enum(['global', 'project']),
  content: z.string(),
}, async ({ scope, content }) => {
  try { return ok(await runRetroAppend(scope, content)); }
  catch (e) { return err(String(e)); }
});

server.tool('arch_solo_declare', { hash: z.string() }, async ({ hash }) => {
  try { return ok(await runSoloDeclare(hash)); }
  catch (e) { return err(String(e)); }
});

server.tool('arch_version', {}, async () => {
  try { return ok(await runVersion()); }
  catch (e) { return err(String(e)); }
});

const transport = new StdioServerTransport();
await server.connect(transport);
```

- [ ] **Step 4: Run integration test to verify it passes**

```bash
npm test -- tests/integration.test.ts
```

Expected: PASS — 1 test.

- [ ] **Step 5: Run the full test suite**

```bash
npm test
```

Expected: all tests pass (Tasks 2–8 unit tests + integration test). Note the count — it should be 17+ tests.

- [ ] **Step 6: Build and smoke-test the binary**

```bash
npm run build
echo '{}' | timeout 2 node dist/index.js || true
```

Expected: process starts and exits cleanly (no unhandled errors in stderr). It will exit after 2 seconds because no MCP client connected — that is expected.

- [ ] **Step 7: Commit**

```bash
git add src/index.ts tests/integration.test.ts
git commit -m "feat: wire MCP server entry point with all 7 tools"
```

---

### Task 10: Register with Claude Code

After the server binary is built and passes tests, wire it into Claude Code.

- [ ] **Step 1: Add arch-mcp to Claude Code MCP settings**

Edit `~/.claude/settings.json`. Add under `mcpServers` (create the key if absent):

```json
{
  "mcpServers": {
    "arch-mcp": {
      "command": "node",
      "args": ["/home/valentin/code/arch-mcp/dist/index.js"]
    }
  }
}
```

- [ ] **Step 2: Restart Claude Code and verify tools appear**

In a new Claude Code session, run `/mcp`.

Expected: `arch-mcp` server listed as connected with 7 tools: `arch_anchor`, `arch_shift_read`, `arch_shift_write`, `arch_session_increment`, `arch_retro_append`, `arch_solo_declare`, `arch_version`.

- [ ] **Step 3: Smoke-test arch_anchor via the MCP tool**

Ask Claude Code: "Call arch_anchor and show me the result."

Expected: JSON response with `{ success: true, data: { dirty: ..., hash: "...", uncommitted_files: [...] } }`.

- [ ] **Step 4: Commit the settings change in arch-protocol**

In `~/code/arch-protocol/`, note the MCP server registration is complete in a short commit:

```bash
cd ~/code/arch-protocol
git add .claude/settings.json 2>/dev/null || true
git commit -m "chore: register arch-mcp server in Claude Code settings" 2>/dev/null || echo "settings.json not tracked — that is fine"
```

Note: `~/.claude/settings.json` is a global file not tracked in any repo. This step just confirms the registration was done.
