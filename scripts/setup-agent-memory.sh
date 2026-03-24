#!/usr/bin/env bash
# setup-agent-memory.sh — Scaffold memory structure and register ingestion cron for an agent
# Usage: setup-agent-memory.sh --agent-id <id> --workspace <path> --agent-name <name> [options]

set -euo pipefail

# ─── Defaults ────────────────────────────────────────────────────────────────
AGENT_ID=""
WORKSPACE=""
AGENT_NAME=""
SESSION_AGENT=""
TIMEZONE="UTC"
DRY_RUN=false

# ─── Help ─────────────────────────────────────────────────────────────────────
usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Scaffold memory directory structure and register a session ingestion cron for an agent.

Required:
  --agent-id      <id>       Unique identifier for the agent (e.g. herald)
  --workspace     <path>     Absolute path to the agent's workspace directory
  --agent-name    <name>     Human-readable agent name (e.g. "Herald")

Optional:
  --session-agent <agent>    Session agent to target for cron messages (default: same as agent-id)
  --timezone      <tz>       Timezone for the agent (default: UTC)
  --dry-run                  Print what would be done without making changes
  --help                     Show this help message

Examples:
  $(basename "$0") --agent-id herald --workspace ~/clawd/agents/herald --agent-name "Herald"
  $(basename "$0") --agent-id herald --workspace ~/clawd/agents/herald --agent-name "Herald" --dry-run
EOF
}

# ─── Arg Parsing ──────────────────────────────────────────────────────────────
while [[ $# -gt 0 ]]; do
  case "$1" in
    --agent-id)      AGENT_ID="$2";      shift 2 ;;
    --workspace)     WORKSPACE="$2";     shift 2 ;;
    --agent-name)    AGENT_NAME="$2";    shift 2 ;;
    --session-agent) SESSION_AGENT="$2"; shift 2 ;;
    --timezone)      TIMEZONE="$2";      shift 2 ;;
    --dry-run)       DRY_RUN=true;       shift   ;;
    --help|-h)       usage; exit 0       ;;
    *)
      echo "❌ Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

# ─── Validation ───────────────────────────────────────────────────────────────
ERRORS=()
[[ -z "$AGENT_ID" ]]   && ERRORS+=("--agent-id is required")
[[ -z "$WORKSPACE" ]]  && ERRORS+=("--workspace is required")
[[ -z "$AGENT_NAME" ]] && ERRORS+=("--agent-name is required")

if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo "❌ Missing required arguments:" >&2
  for err in "${ERRORS[@]}"; do
    echo "   • $err" >&2
  done
  echo "" >&2
  usage >&2
  exit 1
fi

# Default session-agent to agent-id if not specified
[[ -z "$SESSION_AGENT" ]] && SESSION_AGENT="$AGENT_ID"

# Expand ~ in workspace path
WORKSPACE="${WORKSPACE/#\~/$HOME}"

# ─── Summary State ────────────────────────────────────────────────────────────
ACTIONS_TAKEN=()
ACTIONS_SKIPPED=()

# ─── Helpers ──────────────────────────────────────────────────────────────────
do_or_dry() {
  # Usage: do_or_dry "description" command [args...]
  local desc="$1"; shift
  if $DRY_RUN; then
    echo "  [dry-run] Would: $desc"
    ACTIONS_SKIPPED+=("$desc")
  else
    "$@"
    ACTIONS_TAKEN+=("$desc")
  fi
}

make_dir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    ACTIONS_SKIPPED+=("Directory already exists: $dir")
  else
    do_or_dry "Create directory: $dir" mkdir -p "$dir"
  fi
}

# ─── Header ───────────────────────────────────────────────────────────────────
echo ""
echo "🧠 setup-agent-memory"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Agent ID:      $AGENT_ID"
echo "  Agent Name:    $AGENT_NAME"
echo "  Workspace:     $WORKSPACE"
echo "  Session Agent: $SESSION_AGENT"
echo "  Timezone:      $TIMEZONE"
$DRY_RUN && echo "  Mode:          DRY RUN (no changes will be made)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─── Step 1: Scaffold Memory Directories ─────────────────────────────────────
echo "📁 Scaffolding memory directories..."

MEMORY_DIR="$WORKSPACE/memory"
make_dir "$MEMORY_DIR"
make_dir "$MEMORY_DIR/consolidated"
make_dir "$MEMORY_DIR/archive"
make_dir "$MEMORY_DIR/metrics"

# ─── Step 2: Create MEMORY.md ─────────────────────────────────────────────────
echo "📄 Checking MEMORY.md..."

MEMORY_FILE="$WORKSPACE/MEMORY.md"
TODAY="$(date +%Y-%m-%d)"

if [[ -f "$MEMORY_FILE" ]]; then
  echo "  ℹ️  MEMORY.md already exists — skipping"
  ACTIONS_SKIPPED+=("MEMORY.md already exists at $MEMORY_FILE")
else
  MEMORY_CONTENT="# MEMORY.md — $AGENT_NAME
_Last updated: ${TODAY}
_Agent ID: ${AGENT_ID}_

---

## 1. Personal Info
<!-- Facts about the user relevant to this agent's operation -->
<!-- Format: [YYYY-MM-DD] Fact -->

## 2. Preferences
<!-- Patterns in what the user wants from this agent -->
<!-- Format: [YYYY-MM-DD] Preference -->

## 3. Events
<!-- Key events that affected this agent's behaviour or context -->
<!-- Format: [YYYY-MM-DD] Event description -->

## 4. Temporal Data
<!-- Time-sensitive information: deadlines, schedules, recurrences -->
<!-- Format: [YYYY-MM-DD] (expires: YYYY-MM-DD) Data -->

## 5. Updates
<!-- Changes to this agent's config, prompts, tools, or behaviour -->
<!-- Format: [YYYY-MM-DD] What changed and why -->

## 6. Assistant Info
<!-- What this agent has learned about itself: capabilities, limits, identity -->
<!-- Format: [YYYY-MM-DD] Fact -->

---
_Memory ingestion runs every 2 hours via cron (memory-ingest-${AGENT_ID})._
_Do not delete entries — mark superseded facts in the Corrections section of MEMORY-agent.md._
"

  do_or_dry "Create MEMORY.md at $MEMORY_FILE" bash -c "cat > '$MEMORY_FILE' <<'HEREDOC'
$MEMORY_CONTENT
HEREDOC"
fi

# ─── Step 3: Create LEARNINGS.md ──────────────────────────────────────────────
echo "📄 Checking LEARNINGS.md..."

LEARNINGS_FILE="$WORKSPACE/LEARNINGS.md"

if [[ -f "$LEARNINGS_FILE" ]]; then
  echo "  ℹ️  LEARNINGS.md already exists — skipping"
  ACTIONS_SKIPPED+=("LEARNINGS.md already exists at $LEARNINGS_FILE")
else
  LEARNINGS_CONTENT="# LEARNINGS.md — $AGENT_NAME
_Last updated: ${TODAY}
_Agent ID: ${AGENT_ID}_

Lessons learned from operation. More narrative than MEMORY.md — captures
the *why* behind decisions, patterns observed over time, and things to try.

---

## Patterns Observed
<!-- Recurring patterns in user behaviour, requests, or context -->

## What Works
<!-- Approaches that reliably produce good outcomes -->

## What Doesn't Work
<!-- Things tried and abandoned, with reasons -->

## Open Questions
<!-- Unresolved uncertainties about how to behave in edge cases -->

## Ideas to Try
<!-- Hypotheses about improvements, not yet tested -->

---
_Updated manually or during memory ingestion sessions._
"

  do_or_dry "Create LEARNINGS.md at $LEARNINGS_FILE" bash -c "cat > '$LEARNINGS_FILE' <<'HEREDOC'
$LEARNINGS_CONTENT
HEREDOC"
fi

# ─── Step 4: Check / Register Ingestion Cron ──────────────────────────────────
echo "⏰ Checking ingestion cron..."

CRON_ID="memory-ingest-$AGENT_ID"
CRON_PAYLOAD="Run session memory ingestion for agent $AGENT_NAME (id: $AGENT_ID). Read the last 4 hours of sessions from OpenClaw (sessions_list then sessions_history for recent sessions). Extract memory-worthy facts using the six-vector structure (Personal Info, Preferences, Events, Temporal Data, Updates, Assistant Info). Write new facts to $WORKSPACE/memory/\$(date +%Y-%m-%d)-session-ingestion.md. Skip facts already in $WORKSPACE/MEMORY.md. Log run results at the end of the ingestion file."

CRON_EXISTS=false
if openclaw cron list 2>/dev/null | grep -q "$CRON_ID"; then
  CRON_EXISTS=true
fi

if $CRON_EXISTS; then
  echo "  ℹ️  Cron '$CRON_ID' already registered — skipping"
  ACTIONS_SKIPPED+=("Cron already exists: $CRON_ID")
else
  if $DRY_RUN; then
    echo "  [dry-run] Would register cron: $CRON_ID (every 2 hours)"
    echo "  [dry-run] Cron message: $CRON_PAYLOAD"
    ACTIONS_SKIPPED+=("Register cron: $CRON_ID (every 2 hours) → session-agent: $SESSION_AGENT")
  else
    echo "  Registering cron: $CRON_ID (every 2 hours)..."
    openclaw cron add \
      --name "$CRON_ID" \
      --cron "0 */2 * * *" \
      --tz "$TIMEZONE" \
      --agent "$SESSION_AGENT" \
      --message "$CRON_PAYLOAD" \
      --session isolated
    ACTIONS_TAKEN+=("Registered cron: $CRON_ID (every 2 hours) → session-agent: $SESSION_AGENT")
  fi
fi

# ─── Step 5: Summary ──────────────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Setup complete for: $AGENT_NAME ($AGENT_ID)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if [[ ${#ACTIONS_TAKEN[@]} -gt 0 ]]; then
  echo ""
  echo "Actions taken:"
  for action in "${ACTIONS_TAKEN[@]}"; do
    echo "  ✅ $action"
  done
fi

if [[ ${#ACTIONS_SKIPPED[@]} -gt 0 ]]; then
  echo ""
  echo "Skipped (already done or dry-run):"
  for action in "${ACTIONS_SKIPPED[@]}"; do
    echo "  ⏭️  $action"
  done
fi

echo ""
echo "Memory structure:"
echo "  $WORKSPACE/"
echo "  ├── MEMORY.md        (six-vector memory store)"
echo "  ├── LEARNINGS.md     (narrative learnings)"
echo "  └── memory/"
echo "      ├── consolidated/  (merged memory snapshots)"
echo "      ├── archive/       (old ingestion files)"
echo "      └── metrics/       (ingestion run logs)"
echo ""

if $DRY_RUN; then
  echo "ℹ️  Dry-run mode: no files or crons were modified."
  echo ""
fi
