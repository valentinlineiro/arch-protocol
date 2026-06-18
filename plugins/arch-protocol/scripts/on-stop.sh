#!/bin/bash
# ARCH Protocol — Stop hook
# Extracts LOG (ARCH Kaizen) blocks from Claude's response and persists them
# to ~/.arch/retro.md for use by arch-evolve.

ARCH_RETRO="$HOME/.arch/retro.md"
mkdir -p "$(dirname "$ARCH_RETRO")"

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

# Extract LOG block: from header until the next ## section or end of content
LOG_BLOCK=$(echo "$RESPONSE" | awk '
    /## 📝 LOG \(ARCH Kaizen\)/ { found=1 }
    found && /^## / && !/ARCH Kaizen/ { found=0 }
    found { print }
')

[ -z "$LOG_BLOCK" ] && exit 0

# Append to retro.md with metadata
{
    printf '\n<!-- ARCH LOG | %s | %s -->\n' "$(date '+%Y-%m-%d %H:%M')" "$(pwd)"
    echo "$LOG_BLOCK"
    echo ""
} >> "$ARCH_RETRO"
