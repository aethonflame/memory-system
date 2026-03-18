#!/usr/bin/env bash
# prune.sh — Archive old daily notes and enforce size limits
# Called by the consolidation agent after it writes monthly rollups.
# Usage: bash ~/clawd/memory-system/prune.sh [--dry-run]
set -euo pipefail

WORKSPACE="$HOME/clawd"
MEMORY_DIR="$WORKSPACE/memory"
CONSOLIDATED_DIR="$MEMORY_DIR/consolidated"
ARCHIVE_DIR="$MEMORY_DIR/archive"
DRY_RUN=0

[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1 && echo "🔍 DRY RUN — no files will be moved/deleted"

mkdir -p "$CONSOLIDATED_DIR" "$ARCHIVE_DIR"

TODAY=$(date +%Y-%m-%d)
THIRTY_DAYS_AGO=$(date -v-30d +%Y-%m-%d 2>/dev/null || date -d '30 days ago' +%Y-%m-%d)
SIX_MONTHS_AGO=$(date -v-6m +%Y-%m-%d 2>/dev/null || date -d '6 months ago' +%Y-%m-%d)

echo "📦 Prune run — $TODAY"
echo "  Archive notes older than: $THIRTY_DAYS_AGO"
echo "  Archive consolidated older than: $SIX_MONTHS_AGO"
echo ""

PRUNED=0
ARCHIVED=0

# Move daily notes older than 30 days to consolidated/
# (Consolidation agent should have already rolled these up)
for f in "$MEMORY_DIR"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9].md; do
  [ -f "$f" ] || continue
  NOTE_DATE=$(basename "$f" .md)
  if [[ "$NOTE_DATE" < "$THIRTY_DAYS_AGO" ]]; then
    TARGET="$CONSOLIDATED_DIR/$(basename "$f")"
    if [ $DRY_RUN -eq 1 ]; then
      echo "  [dry] would move $f → $TARGET"
    else
      mv "$f" "$TARGET"
      echo "  ✓ moved $f → $TARGET"
    fi
    PRUNED=$((PRUNED + 1))
  fi
done

# Move consolidated monthly files older than 6 months to archive/
for f in "$CONSOLIDATED_DIR"/*.md; do
  [ -f "$f" ] || continue
  # Monthly files are YYYY-MM.md, daily are YYYY-MM-DD.md
  FNAME=$(basename "$f" .md)
  if [[ "$FNAME" =~ ^[0-9]{4}-[0-9]{2}$ ]]; then
    FILE_DATE="${FNAME}-01"
    if [[ "$FILE_DATE" < "$SIX_MONTHS_AGO" ]]; then
      TARGET="$ARCHIVE_DIR/$(basename "$f")"
      if [ $DRY_RUN -eq 1 ]; then
        echo "  [dry] would archive $f → $TARGET"
      else
        mv "$f" "$TARGET"
        echo "  ✓ archived $f → $TARGET"
      fi
      ARCHIVED=$((ARCHIVED + 1))
    fi
  fi
done

# Check size limits
MEMORY_LINES=$(wc -l < "$WORKSPACE/MEMORY.md")
CONSOLIDATED_SIZE=$(du -sk "$CONSOLIDATED_DIR" 2>/dev/null | cut -f1 || echo 0)
ARCHIVE_SIZE=$(du -sk "$ARCHIVE_DIR" 2>/dev/null | cut -f1 || echo 0)

echo ""
echo "─────────────────────────────────"
echo "Notes moved to consolidated: $PRUNED"
echo "Consolidated archived:       $ARCHIVED"
echo "MEMORY.md size:              $MEMORY_LINES lines (limit: 400)"
echo "Consolidated dir:            ${CONSOLIDATED_SIZE}KB (limit: 500KB)"
echo "Archive dir:                 ${ARCHIVE_SIZE}KB (limit: 5120KB)"
echo "─────────────────────────────────"

if [ "$MEMORY_LINES" -gt 400 ]; then
  echo "⚠️  WARNING: MEMORY.md exceeds 400 lines — needs pruning"
fi

if [ "$CONSOLIDATED_SIZE" -gt 500 ]; then
  echo "⚠️  WARNING: consolidated/ exceeds 500KB"
fi

echo ""
echo "✓ Prune complete."
