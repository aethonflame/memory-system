# Session-Start Memory Ingestion — Design

_Designed: 2026-03-24 | OpenClaw version: 2026.3.13_

---

## Problem Statement

When a new conversation starts, the agent currently boots cold — MEMORY.md is loaded but
any facts from the last few hours of conversations are sitting unprocessed in session history.
We want to warm the context by extracting those facts before the session gets going.

---

## Options Considered

### Option A: session:start hook
**Ideal** — fire a memory ingestion job the moment a session creates.
**Verdict: NOT AVAILABLE.** The `session:start` event is listed as "planned" in the OpenClaw
docs but does not exist in v2026.3.13. We cannot implement this today.

### Option B: message:received hook (custom hook)
Fire on first inbound message of a new session.
**Problems:**
- No way to detect "first message of a new session" vs "any message" from the hook context
- Would run on every single inbound message — extremely wasteful
- Could still miss session starts if no message arrives

### Option C: Short-interval cron (every 15–30 min)
Run the session ingestion program as an isolated cron job every 20–30 minutes.
With `LOOKBACK_HOURS=1`, it checks the last hour of sessions.
**Result:** Any new session is captured within 20–30 minutes of starting.
**Verdict: ✅ RECOMMENDED.** Fits existing cron infrastructure, is reliable, low overhead.

### Option D: Add session-start ingestion to HEARTBEAT.md
Instruct the heartbeat to trigger ingestion.
**Problems:**
- Heartbeat runs in main session — sessions_list/sessions_history would be available,
  but running ingestion logic in the heartbeat bloats it and violates the "keep heartbeats
  lightweight" principle
- Not meaningfully faster than Option C

### Option E: Custom hook on message:preprocessed with session-newness heuristic
Write a custom hook that fires on `message:preprocessed`, checks if the session is "new"
(e.g. message count == 1), and triggers ingestion.
**Problems:**
- Complex, fragile heuristic
- Hooks run synchronously in command processing — triggering a full agent turn from a hook
  is not a supported pattern; the hook can only write files or push short messages
- Better fit once `session:start` is available

---

## Recommended Approach: 20-Minute Cron

### Design

An isolated cron job runs every 20 minutes (on the 5-minute offset to avoid top-of-hour
contention). It runs the session ingestion program with:

```
AGENT_ID=main
WORKSPACE=/Users/aethon/clawd
LOOKBACK_HOURS=1
```

This means any session that's started in the last hour gets processed. Maximum lag from
session-start to memory ingestion: **~20 minutes**. For a typical conversation that runs
30+ minutes, this means memory is warmed during the session itself.

### Session-Ingestion Program

The program at `programs/session-ingestion/PROGRAM.md` already handles this exactly.
It reads recent sessions, extracts memory-worthy facts, and writes to today's daily note.
The nightly consolidation then promotes those facts to MEMORY.md.

### Output Location

The ingestion cron writes to `~/clawd/memory/YYYY-MM-DD.md` (today's daily note).
The nightly consolidation picks this up naturally — no extra wiring needed.

For the two systems to coordinate cleanly, we add a Step 0 to the nightly consolidation
PROGRAM.md that explicitly checks for a `memory/session-ingestion-YYYY-MM-DD.md` file.
However, since the ingestion program writes to the standard daily note (not a separate file),
the better approach is: nightly consolidation reads all of `memory/YYYY-MM-DD.md` as always,
which already includes ingestion blocks. No separate file needed.

### Cron Spec

```json
{
  "name": "Session memory ingestion",
  "schedule": { "kind": "cron", "expr": "5,25,45 * * * *", "tz": "Asia/Singapore" },
  "sessionTarget": "isolated",
  "wakeMode": "now",
  "payload": {
    "kind": "agentTurn",
    "message": "Read ~/code/memory-system/programs/session-ingestion/PROGRAM.md and follow it exactly.\n\nParameters:\n- AGENT_ID=main\n- WORKSPACE=/Users/aethon/clawd\n- LOOKBACK_HOURS=1\n\nThis is a session-start ingestion run. Process recent sessions, extract memory-worthy facts, write to today's daily note. When done reply INGESTION_COMPLETE followed by a one-line summary.",
    "lightContext": true,
    "timeoutSeconds": 120
  },
  "delivery": {
    "mode": "none"
  }
}
```

### Rationale for delivery.mode: "none"

This runs silently in the background. No Telegram message needed — it's infrastructure,
not a user-facing action. The nightly consolidation run (which IS delivered) will reflect
the facts that ingestion surfaced.

### lightContext: true

Since this job only needs to run the ingestion program (not the full workspace context),
`lightContext: true` keeps the token cost low. The ingestion program has all its own
instructions in PROGRAM.md.

---

## What's NOT Needed

- No config changes to `session-memory` hook — it works fine for `/new` snapshots
- No custom hook implementation — cron handles this more cleanly
- No `~/.openclaw/openclaw.json` changes — cron is managed via `openclaw cron add` or
  directly via the cron tool

---

## Adding the Cron Job

The cron job should be added via the agent's cron tool call (or via CLI):

```bash
openclaw cron add \
  --name "Session memory ingestion" \
  --cron "5,25,45 * * * *" \
  --tz "Asia/Singapore" \
  --session isolated \
  --message "Read ~/code/memory-system/programs/session-ingestion/PROGRAM.md and follow it exactly.\n\nParameters:\n- AGENT_ID=main\n- WORKSPACE=/Users/aethon/clawd\n- LOOKBACK_HOURS=1\n\nThis is a session-start ingestion run. Process recent sessions, extract memory-worthy facts, write to today's daily note. When done reply INGESTION_COMPLETE followed by a one-line summary." \
  --light-context \
  --timeout 120 \
  --delivery none
```

Or let Justin's main agent add it with: "Add the session ingestion cron from
`~/code/memory-system/programs/session-ingestion/session-start-cron.json`"

---

## Future: When session:start Arrives

Once OpenClaw ships `session:start` as a real hook event, we can replace the cron with
a proper hook. The handler would:
1. Log the session key
2. Trigger an isolated cron turn (or write a flag file for the heartbeat to pick up)

Until then, the 20-minute cron is the pragmatic solution.
