#!/bin/bash
# ARCH Protocol — Stop hook
# Extracts LOG (ARCH Kaizen) blocks from Claude's response and persists them.
#
# Always writes to:   ~/.arch/retro.md  (global — for evolving SKILL.md)
# Also writes to:     ./.arch/retro.md  (local — if .arch/ exists in current project)

ARCH_GLOBAL="$HOME/.arch/retro.md"
ARCH_LOCAL="$(pwd)/.arch/retro.md"

mkdir -p "$(dirname "$ARCH_GLOBAL")"

INPUT=$(cat)

TRANSCRIPT_PATH=$(echo "$INPUT" | jq -r '.transcript_path // empty' 2>/dev/null)
[ -z "$TRANSCRIPT_PATH" ] || [ ! -f "$TRANSCRIPT_PATH" ] && exit 0

# Allow transcript to flush before reading
sleep 0.3

# Extract the last assistant response as plain text
RESPONSE=$(jq -rs '
    [.[] | select(.type == "assistant" and (.message.content | type == "array"))] | last |
    [.message.content[] | select(.type == "text") | .text] | join("\n")
' "$TRANSCRIPT_PATH" 2>/dev/null)

[ -z "$RESPONSE" ] && exit 0

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

# Build the entry with metadata
ENTRY=$(printf '\n<!-- ARCH LOG | %s | %s -->\n%s\n' \
    "$(date '+%Y-%m-%d %H:%M')" \
    "$(pwd)" \
    "$LOG_BLOCK")

# Always write globally
echo "$ENTRY" >> "$ARCH_GLOBAL"

# Write locally only if the project has opted in (.arch/ directory exists)
if [ -d "$(pwd)/.arch" ]; then
    echo "$ENTRY" >> "$ARCH_LOCAL"
fi
