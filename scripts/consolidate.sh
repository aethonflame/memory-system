#!/usr/bin/env bash
# consolidate.sh — Manual trigger for memory consolidation
# Normally runs via cron at 03:00 SGT daily.
# Usage: bash ~/clawd/memory-system/consolidate.sh
set -euo pipefail

WORKSPACE="$HOME/clawd"
PROGRAM="$WORKSPACE/memory-system/PROGRAM.md"
LOG_DIR="$WORKSPACE/memory-system/runs"
TODAY=$(date +%Y-%m-%d)

if [ ! -f "$PROGRAM" ]; then
  echo "ERROR: PROGRAM.md not found at $PROGRAM"
  exit 1
fi

mkdir -p "$LOG_DIR"

echo "🧠 Starting memory consolidation — $(date '+%Y-%m-%d %H:%M SGT')"
echo "Program: $PROGRAM"
echo "Log: $LOG_DIR/$TODAY.md"
echo ""

# Spawn OpenClaw isolated agent with the consolidation task
openclaw run --isolated --workspace "$WORKSPACE" \
  --message "$(cat "$PROGRAM")" \
  --timeout 300 2>&1

echo ""
echo "✓ Consolidation complete."
