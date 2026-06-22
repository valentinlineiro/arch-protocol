#!/usr/bin/env bash
# ARCH Protocol — Project initializer
# Run once per project to enable local LOG capture and verify hook activation.
set -euo pipefail

echo "🏗  ARCH init"
echo ""

# Verify we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "❌ No git repository found. Run from the root of a git project."
  exit 1
fi

# Enable local LOG capture
if [ ! -d ".arch" ]; then
  mkdir .arch
  echo "✅ .arch/ created — local LOG capture enabled"
else
  echo "ℹ️  .arch/ already exists — local LOG capture was already enabled"
fi

# Keep .arch/ out of version control
if [ -f ".gitignore" ]; then
  if ! grep -qxF ".arch/" .gitignore; then
    echo ".arch/" >> .gitignore
    echo "✅ .arch/ added to .gitignore"
  else
    echo "ℹ️  .arch/ already in .gitignore"
  fi
else
  echo ".arch/" > .gitignore
  echo "✅ .gitignore created with .arch/"
fi

# Auto-activate ARCH via CLAUDE.md
ARCH_MARKER="## ARCH Protocol"
if [ -f "CLAUDE.md" ]; then
  if ! grep -qF "$ARCH_MARKER" CLAUDE.md; then
    printf '\n## ARCH Protocol\nThis project uses the ARCH protocol. Apply it to every task.\n' >> CLAUDE.md
    echo "✅ ARCH Protocol added to CLAUDE.md — will activate automatically each session"
  else
    echo "ℹ️  CLAUDE.md already contains the ARCH Protocol section"
  fi
else
  printf '## ARCH Protocol\nThis project uses the ARCH protocol. Apply it to every task.\n' > CLAUDE.md
  echo "✅ CLAUDE.md created with ARCH Protocol section"
fi

# Verify global retro file is reachable
GLOBAL="$HOME/.arch/retro.md"
if [ -f "$GLOBAL" ]; then
  COUNT=$(grep -c "## 📝 LOG" "$GLOBAL" 2>/dev/null || echo 0)
  echo "ℹ️  Global LOGs accumulated: $COUNT"
elif [ -d "$HOME/.arch" ]; then
  echo "ℹ️  ~/.arch/ exists but retro.md is still empty — the hook will write here after the first session"
else
  echo "⚠️  arch-protocol plugin not detected. To install it, run in Claude Code:"
  echo "   /plugin add-marketplace https://github.com/valentinlineiro/arch-protocol"
  echo "   /plugin install arch-protocol@arch-protocol"
fi

echo ""
echo "✅ ARCH is active for this project."
echo "   Next: open Claude Code and start working."
echo "   Tip: run arch-evolve after 10+ LOGs to improve the protocol."
