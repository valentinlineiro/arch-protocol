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

# Verify global retro file is reachable
GLOBAL="$HOME/.arch/retro.md"
if [ -f "$GLOBAL" ]; then
  COUNT=$(grep -c "## 📝 LOG" "$GLOBAL" 2>/dev/null || echo 0)
  echo "ℹ️  LOGs globales acumulados: $COUNT"
elif [ -d "$HOME/.arch" ]; then
  echo "ℹ️  ~/.arch/ existe pero retro.md aún está vacío — el hook escribirá aquí al terminar la primera sesión"
else
  echo "⚠️  ~/.arch/ no encontrado — el hook de Claude Code puede no estar activo."
  echo "   Asegúrate de que el plugin arch-protocol está instalado en Claude Code."
fi

echo ""
echo "✅ ARCH está activo para este proyecto."
echo "   Próximo paso: abre Claude Code y empieza a trabajar."
echo "   Tip: ejecuta arch-evolve después de 10+ LOGs para mejorar el protocolo."
