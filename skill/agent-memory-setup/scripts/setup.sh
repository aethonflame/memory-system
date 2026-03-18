#!/usr/bin/env bash
# setup.sh — scaffold the memory-system into another workspace/root
# Usage:
#   bash scripts/setup.sh --mode single-agent --path /path/to/workspace
#   bash scripts/setup.sh --mode shared-drive --path /path/to/shared-root
# If --mode is omitted, interactive mode is used by default.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE=""
TARGET=""
INTERACTIVE=1

GREEN="\033[0;32m"; YELLOW="\033[0;33m"; BOLD="\033[1m"; RESET="\033[0m"
ok()   { echo -e "${GREEN}✓${RESET} $*"; }
skip() { echo -e "${YELLOW}~${RESET} $* (already exists, skipped)"; }
section() { echo -e "\n${BOLD}── $* ──${RESET}"; }

die() { echo "ERROR: $*" >&2; exit 1; }

usage() {
  cat << 'EOF'
Usage:
  bash scripts/setup.sh [--mode <single-agent|codebase|shared-drive>] [--path <target>]

Notes:
- If --mode is omitted, interactive mode is used by default.
- codebase currently behaves like single-agent, but exists as a clearer semantic mode.
- Supplying --mode makes setup non-interactive; if --path is omitted, it defaults to the current directory.
EOF
}

ensure_dir() {
  local dir="$1"
  if [ -d "$dir" ]; then skip "$dir/"; else mkdir -p "$dir" && ok "Created $dir/"; fi
}

copy_if_missing() {
  local src="$1" dst="$2"
  if [ -e "$dst" ]; then skip "$dst"; else mkdir -p "$(dirname "$dst")" && cp "$src" "$dst" && ok "Created $dst"; fi
}

write_daily_note_if_missing() {
  local target_dir="$1"
  local today
  today=$(date +%Y-%m-%d)
  local dst="$target_dir/memory/$today.md"
  if [ -e "$dst" ]; then skip "$dst"; else
    sed "s/__DATE__/$today/g" "$REPO_ROOT/templates/daily-note.md.template" > "$dst"
    ok "Created $dst"
  fi
}

scaffold_single_agent() {
  local root="$1"
  section "Single-agent / codebase memory scaffold"
  ensure_dir "$root/memory"
  ensure_dir "$root/memory/consolidated"
  ensure_dir "$root/memory/archive"
  ensure_dir "$root/memory/metrics"
  ensure_dir "$root/learnings"
  ensure_dir "$root/memory-system"
  ensure_dir "$root/memory-system/runs"
  ensure_dir "$root/memory-system/programs/single-agent"

  copy_if_missing "$REPO_ROOT/templates/MEMORY.md.template" "$root/MEMORY.md"
  copy_if_missing "$REPO_ROOT/templates/LEARNINGS.md.template" "$root/LEARNINGS.md"
  copy_if_missing "$REPO_ROOT/templates/LEARNINGS.md.template" "$root/learnings/LEARNINGS.md"
  copy_if_missing "$REPO_ROOT/programs/single-agent/PROGRAM.md" "$root/memory-system/PROGRAM.md"
  copy_if_missing "$REPO_ROOT/programs/single-agent/PROGRAM.md" "$root/memory-system/programs/single-agent/PROGRAM.md"
  copy_if_missing "$REPO_ROOT/templates/ground-truth.template.json" "$root/memory-system/ground-truth.json"
  copy_if_missing "$REPO_ROOT/scripts/consolidate.sh" "$root/memory-system/consolidate.sh"
  copy_if_missing "$REPO_ROOT/scripts/eval.sh" "$root/memory-system/eval.sh"
  copy_if_missing "$REPO_ROOT/scripts/prune.sh" "$root/memory-system/prune.sh"
  chmod +x "$root/memory-system/consolidate.sh" "$root/memory-system/eval.sh" "$root/memory-system/prune.sh" 2>/dev/null || true
  write_daily_note_if_missing "$root"

  cat << EOF

Next steps:
  1. Fill in $root/MEMORY.md
  2. Seed $root/learnings/LEARNINGS.md with known gotchas
  3. Add boot instructions to your agent: read MEMORY.md, learnings/LEARNINGS.md, today's + yesterday's daily note
  4. Add a nightly consolidation job that feeds $root/memory-system/PROGRAM.md to your agent
EOF
}

scaffold_shared_drive() {
  local root="$1"
  section "Shared-drive multi-agent memory scaffold"
  ensure_dir "$root/learnings"
  ensure_dir "$root/memory"
  ensure_dir "$root/memory/consolidated"
  ensure_dir "$root/memory/archive"
  ensure_dir "$root/memory/metrics"
  ensure_dir "$root/agents"
  ensure_dir "$root/incoming/segments"
  ensure_dir "$root/state/processed-segments"
  ensure_dir "$root/state/promotions"
  ensure_dir "$root/state/manifests"
  ensure_dir "$root/state/leases"
  ensure_dir "$root/index/snapshots"
  ensure_dir "$root/memory-system"
  ensure_dir "$root/memory-system/runs"
  ensure_dir "$root/memory-system/programs/shared-drive"

  copy_if_missing "$REPO_ROOT/templates/MEMORY.md.template" "$root/MEMORY.md"
  copy_if_missing "$REPO_ROOT/templates/LEARNINGS.md.template" "$root/LEARNINGS.md"
  copy_if_missing "$REPO_ROOT/templates/LEARNINGS.md.template" "$root/learnings/LEARNINGS.md"
  copy_if_missing "$REPO_ROOT/templates/shared-segment.md.template" "$root/incoming/segments/SEGMENT.template.md"
  copy_if_missing "$REPO_ROOT/programs/shared-drive/PROGRAM.md" "$root/memory-system/programs/shared-drive/PROGRAM.md"
  copy_if_missing "$REPO_ROOT/programs/shared-drive/SEGMENT-WRITER.md" "$root/memory-system/programs/shared-drive/SEGMENT-WRITER.md"
  copy_if_missing "$REPO_ROOT/programs/shared-drive/INDEXER.md" "$root/memory-system/programs/shared-drive/INDEXER.md"
  copy_if_missing "$REPO_ROOT/programs/shared-drive/MANIFESTS.md" "$root/memory-system/programs/shared-drive/MANIFESTS.md"
  copy_if_missing "$REPO_ROOT/programs/shared-drive/FAILOVER.md" "$root/memory-system/programs/shared-drive/FAILOVER.md"
  copy_if_missing "$REPO_ROOT/references/shared-drive-multi-agent-design.md" "$root/memory-system/shared-drive-multi-agent-design.md"
  copy_if_missing "$REPO_ROOT/templates/ground-truth.template.json" "$root/memory-system/ground-truth.json"
  copy_if_missing "$REPO_ROOT/scripts/consolidate.sh" "$root/memory-system/consolidate.sh"
  copy_if_missing "$REPO_ROOT/scripts/eval.sh" "$root/memory-system/eval.sh"
  copy_if_missing "$REPO_ROOT/scripts/prune.sh" "$root/memory-system/prune.sh"
  chmod +x "$root/memory-system/consolidate.sh" "$root/memory-system/eval.sh" "$root/memory-system/prune.sh" 2>/dev/null || true
  : > "$root/index/CURRENT"
  : > "$root/state/processed-segments/.gitkeep"
  : > "$root/state/promotions/.gitkeep"
  : > "$root/state/manifests/.gitkeep"
  : > "$root/state/leases/.gitkeep"

  cat << EOF

Next steps:
  1. Treat $root/incoming/segments as the ONLY multi-writer area
  2. Pin one host as consolidator/indexer; only it may publish MEMORY.md, LEARNINGS.md, memory/*.md and index snapshots
  3. Read $root/memory-system/shared-drive-multi-agent-design.md before rollout
  4. Give runtime agents the rules in $root/memory-system/programs/shared-drive/SEGMENT-WRITER.md
  5. Keep indexes local-per-host or publish immutable snapshots only
EOF
}

interactive_pick_mode() {
  echo "No --mode supplied. Defaulting to interactive setup."
  echo ""
  echo "Select mode:"
  echo "  1) single-agent  — one agent / one workspace"
  echo "  2) codebase      — same scaffold, framed for a project repo"
  echo "  3) shared-drive  — many agents writing raw segments; one consolidator publishes canonical memory"
  printf "Enter choice [1-3]: "
  read -r choice
  case "$choice" in
    1) MODE="single-agent" ;;
    2) MODE="codebase" ;;
    3) MODE="shared-drive" ;;
    *) die "invalid choice: $choice" ;;
  esac
}

interactive_pick_target() {
  local default
  default="$(pwd)"
  printf "Target path [%s]: " "$default"
  read -r input
  TARGET="${input:-$default}"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      MODE="${2:-}"; INTERACTIVE=0; shift 2 ;;
    --path|--target)
      TARGET="${2:-}"; shift 2 ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      die "unknown argument: $1" ;;
  esac
done

if [[ -z "$MODE" ]]; then
  interactive_pick_mode
fi

if [[ -z "$TARGET" ]]; then
  if [[ "$INTERACTIVE" -eq 1 ]]; then
    interactive_pick_target
  else
    TARGET="$(pwd)"
  fi
fi

mkdir -p "$TARGET"
TARGET="$(cd "$TARGET" && pwd)"

echo ""
echo "Repo root:   $REPO_ROOT"
echo "Mode:        $MODE"
echo "Target path: $TARGET"
echo ""

case "$MODE" in
  single-agent|codebase)
    scaffold_single_agent "$TARGET" ;;
  shared-drive)
    scaffold_shared_drive "$TARGET" ;;
  *)
    die "unsupported mode: $MODE" ;;
esac

echo ""
ok "Done."
