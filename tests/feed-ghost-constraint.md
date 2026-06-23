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
