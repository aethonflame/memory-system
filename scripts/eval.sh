#!/usr/bin/env bash
# eval.sh — Memory system evaluation
# Runs test queries against QMD and scores recall/precision/latency.
# Usage: bash ~/clawd/memory-system/eval.sh
# Output: memory/metrics/YYYY-MM-DD.json + updates dashboard.md
set -euo pipefail

WORKSPACE="$HOME/clawd"
GROUND_TRUTH="$HOME/code/memory-system/ground-truth.json"
METRICS_DIR="$WORKSPACE/memory/metrics"
DASHBOARD="$METRICS_DIR/dashboard.md"
TODAY=$(date +%Y-%m-%d)
OUTPUT="$METRICS_DIR/$TODAY.json"
QMD_BIN="$HOME/.bun/bin/qmd"
QMD_CACHE="$HOME/.openclaw/agents/main/qmd/xdg-cache"
export XDG_CACHE_HOME="$QMD_CACHE"

mkdir -p "$METRICS_DIR"

if [ ! -f "$GROUND_TRUTH" ]; then
  echo "ERROR: ground-truth.json not found"
  exit 1
fi

if [ ! -f "$QMD_BIN" ]; then
  echo "ERROR: qmd not found at $QMD_BIN"
  exit 1
fi

TOTAL=$(jq '.queries | length' "$GROUND_TRUTH")
HITS=0
TOTAL_LATENCY=0

echo "🔍 Evaluating memory system — $TOTAL queries"
echo ""

RESULTS='[]'

for i in $(seq 0 $((TOTAL - 1))); do
  QUERY=$(jq -r ".queries[$i].query" "$GROUND_TRUTH")
  QUERY_ID=$(jq -r ".queries[$i].id" "$GROUND_TRUTH")
  KEYWORDS=$(jq -r ".queries[$i].expected_keywords[]" "$GROUND_TRUTH")

  # Use 'query' (hybrid BM25 + vectors + reranking) — all models are downloaded and cached.
  # Falls back to 'search' (BM25 only) if query fails (e.g. model crash, timeout).
  START_S=$(date +%s)
  QMD_OUTPUT=$("$QMD_BIN" query --json "$QUERY" 2>/dev/null || "$QMD_BIN" search --json "$QUERY" 2>/dev/null || echo '[]')
  END_S=$(date +%s)
  LATENCY=$(( (END_S - START_S) * 1000 ))
  TOTAL_LATENCY=$((TOTAL_LATENCY + LATENCY))

  # Check if any expected keyword appears in the results
  HIT=0
  RESULT_TEXT=$(echo "$QMD_OUTPUT" | jq -r '.[].snippet // .[].text // .[].content // ""' 2>/dev/null | awk '{print tolower($0)}' || echo "")
  while IFS= read -r KW; do
    [ -z "$KW" ] && continue
    KW_LOWER=$(echo "$KW" | awk '{print tolower($0)}')
    if echo "$RESULT_TEXT" | awk -v kw="$KW_LOWER" 'index($0, kw) > 0 {found=1} END {exit !found}' 2>/dev/null; then
      HIT=1
      break
    fi
  done <<< "$KEYWORDS"

  HITS=$((HITS + HIT))
  STATUS=$([ $HIT -eq 1 ] && echo "hit" || echo "miss")
  printf "  [%s] %s — %s (%dms)\n" "$QUERY_ID" "$STATUS" "$QUERY" "$LATENCY"

  RESULTS=$(echo "$RESULTS" | jq ". + [{\"id\": \"$QUERY_ID\", \"query\": $(echo "$QUERY" | jq -R .), \"hit\": $HIT, \"latency_ms\": $LATENCY}]")
done

AVG_LATENCY=$((TOTAL_LATENCY / TOTAL))
RECALL=$(echo "scale=2; $HITS / $TOTAL" | bc)
MEMORY_LINES=$(wc -l < "$WORKSPACE/MEMORY.md")

echo ""
echo "─────────────────────────────────"
echo "Recall@5:     $RECALL  ($HITS/$TOTAL)"
echo "Avg latency:  ${AVG_LATENCY}ms"
echo "MEMORY.md:    ${MEMORY_LINES} lines"
echo "─────────────────────────────────"

# Write JSON results
cat > "$OUTPUT" << EOF
{
  "date": "$TODAY",
  "recall": $RECALL,
  "hits": $HITS,
  "total": $TOTAL,
  "avg_latency_ms": $AVG_LATENCY,
  "memory_lines": $MEMORY_LINES,
  "results": $RESULTS
}
EOF

echo ""
echo "✓ Results written to $OUTPUT"
echo "✓ Update dashboard.md manually or re-run consolidation to refresh."
