#!/bin/bash
# ARCH Protocol — Session-start hook
# Writes ~/.arch/anchor_state with dirty status and HEAD hash.
# Eliminates first-task ANCHOR ceremony — protocol reads this file instead of running git.

ARCH_DIR="$HOME/.arch"
ANCHOR_STATE="$ARCH_DIR/anchor_state"

mkdir -p "$ARCH_DIR"

# Only run inside a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    exit 0
fi

DIRTY=$(git status --short)
if [ -n "$DIRTY" ]; then
    echo "dirty=true" > "$ANCHOR_STATE"
else
    echo "dirty=false" > "$ANCHOR_STATE"
fi

echo "hash=$(git rev-parse HEAD)" >> "$ANCHOR_STATE"
