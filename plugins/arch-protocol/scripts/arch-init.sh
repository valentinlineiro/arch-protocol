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
  echo "✅ .arch/ creado — local LOG capture habilitado"
else
  echo "ℹ️  .arch/ ya existe — local LOG capture ya estaba habilitado"
fi

# Keep .arch/ out of version control
if [ -f ".gitignore" ]; then
  if ! grep -qxF ".arch/" .gitignore; then
    echo ".arch/" >> .gitignore
    echo "✅ .arch/ añadido a .gitignore"
  else
    echo "ℹ️  .arch/ ya está en .gitignore"
  fi
else
  echo ".arch/" > .gitignore
  echo "✅ .gitignore creado con .arch/"
fi

# Auto-activate ARCH via CLAUDE.md
ARCH_MARKER="## ARCH Protocol"
if [ -f "CLAUDE.md" ]; then
  if ! grep -qF "$ARCH_MARKER" CLAUDE.md; then
    printf '\n## ARCH Protocol\nThis project uses the ARCH protocol. Apply it to every task.\n' >> CLAUDE.md
    echo "✅ ARCH Protocol añadido a CLAUDE.md — se activará automáticamente en cada sesión"
  else
    echo "ℹ️  CLAUDE.md ya contiene la sección ARCH Protocol"
  fi
else
  printf '## ARCH Protocol\nThis project uses the ARCH protocol. Apply it to every task.\n' > CLAUDE.md
  echo "✅ CLAUDE.md creado con sección ARCH Protocol"
fi

# Verify global retro file is reachable
GLOBAL="$HOME/.arch/retro.md"
if [ -f "$GLOBAL" ]; then
  COUNT=$(grep -c "## 📝 LOG" "$GLOBAL" 2>/dev/null || echo 0)
  echo "ℹ️  LOGs globales acumulados: $COUNT"
elif [ -d "$HOME/.arch" ]; then
  echo "ℹ️  ~/.arch/ existe pero retro.md aún está vacío — el hook escribirá aquí al terminar la primera sesión"
else
  echo "⚠️  Plugin arch-protocol no detectado. Para instalarlo, ejecuta en Claude Code:"
  echo "   /plugin add-marketplace https://github.com/valentinlineiro/arch-protocol"
  echo "   /plugin install arch-protocol@arch-protocol"
fi

echo ""
echo "✅ ARCH está activo para este proyecto."
echo "   Próximo paso: abre Claude Code y empieza a trabajar."
echo "   Tip: ejecuta arch-evolve después de 10+ LOGs para mejorar el protocolo."
