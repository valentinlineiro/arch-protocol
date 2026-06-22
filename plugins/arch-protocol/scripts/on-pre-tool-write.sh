#!/bin/bash
# ARCH Protocol — PreToolUse hook (Write/Edit)
# Blocks file writes unless a matching solo_declared_<hash> file exists.
# Enforces that SOLO was declared before code is written.
# Exit 2 = block the tool call with an error message.

ARCH_DIR="$HOME/.arch"
ANCHOR_STATE="$ARCH_DIR/anchor_state"

# If anchor_state doesn't exist (non-git or first run), allow write
[ -f "$ANCHOR_STATE" ] || exit 0

HASH=$(grep '^hash=' "$ANCHOR_STATE" | cut -d= -f2)
[ -z "$HASH" ] && exit 0

if [ ! -f "$ARCH_DIR/solo_declared_$HASH" ]; then
    echo "ARCH: SOLO not declared for current task. Write the 🎯 GATE+PULL (S): ... → [what will change] line (S tasks) or 🎯 SOLO: declaration (M/L tasks) before writing code." >&2
    exit 2
fi
