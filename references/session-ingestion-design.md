# Session Ingestion — Architecture Design

## Problem

The memory system consolidates daily notes into `MEMORY.md` nightly. But daily notes are
written manually — by agents that are supposed to remember to write them. In practice:

- Agents forget to write notes mid-session
- New sessions start cold when prior sessions didn't produce notes
- Conversation transcripts contain the actual facts, but they're never mined

The session ingestion program closes this gap by **automatically extracting memory from
conversation history** using OpenClaw's sessions API.

---

## Architecture

```
OpenClaw Sessions API
        │
        ▼
 sessions_list (filter by AGENT_ID, LOOKBACK_HOURS)
        │
        ▼
 sessions_history (per session, assistant + user turns only)
        │
        ▼
 Six-Vector Extraction
  ├─ Personal Info
  ├─ Preferences
  ├─ Events
  ├─ Temporal Data
  ├─ Updates (contradiction-flagged)
  └─ Assistant Info
        │
        ▼
 Deduplication Check (vs MEMORY.md + today's daily note)
        │
        ├─ Already known → discard
        ├─ New fact → queue for daily note
        └─ Contradicts MEMORY.md → queue with ⚠️ CONTRADICTION flag
                │
                ▼
        WORKSPACE/memory/YYYY-MM-DD.md
        (append-only ingestion block)
                │
                ▼
        memory-system/runs/ingestion-YYYY-MM-DD.md
        (run log append)
                │
                ▼ (nightly, separate program)
        MEMORY.md consolidation
```

---

## Design Decisions

### Why daily notes, not MEMORY.md directly

The consolidation agent curates `MEMORY.md` with full context across multiple days.
Session ingestion is a raw extraction pass — it may miss nuance, produce borderline facts,
or flag false contradictions. Routing through daily notes keeps `MEMORY.md` clean and
ensures human-readable audit trails before promotion.

### Why six-vector extraction

The six vectors (Personal Info, Preferences, Events, Temporal Data, Updates, Assistant Info)
match the structure of `MEMORY.md`. Extracting into these vectors directly means the
consolidation agent can promote facts without re-classifying them.

### Why contradiction flagging rather than direct update

Session ingestion sees a small window of sessions. The consolidation agent has the full
picture across days. Contradictions are flagged with `⚠️ CONTRADICTION` so the consolidator
can decide whether the new fact is truly superseding, or is context-dependent (e.g. a
temporary state that should be Temporal Data, not a correction to Personal Info).

### Why parameterise AGENT_ID and WORKSPACE

Different agents have different memory locations and different extraction contexts. A single
generic program can serve all agents with minimal per-agent override. The Herald variant
(`HERALD.md`) demonstrates this: same core flow, narrowed extraction scope, different
write targets.

### Why skip tool call bodies

Tool calls and their results are operational noise in most cases — raw JSON, file contents,
command output. The conversation turns (user/assistant) are where facts are stated in natural
language, which is what extraction models handle well.

---

## Trigger Points

Two trigger modes are supported:

| Mode | Trigger | LOOKBACK_HOURS | Purpose |
|---|---|---|---|
| Scheduled | Cron every 4 hours | 4 | Background catch-all; ensures no session window is missed |
| Session-start | On new session open | 1 | Warms the current session with very recent context |

The session-start trigger is especially valuable for agents that run frequently (like Herald's
breaking scan). Each new cron invocation can boot with the last hour's sessions already mined.

---

## Agent Compatibility

The program is designed to run on any agent with these tools:

| Tool | Used for |
|---|---|
| `sessions_list` | Discover recent sessions |
| `sessions_history` | Fetch message transcripts |
| `read` | Load MEMORY.md and daily notes for deduplication |
| `write` / `edit` | Write daily note and run log |
| `memory_search` | (optional) semantic dedup for fuzzy fact matching |
| `memory_get` | (optional) targeted fact retrieval |

No external APIs, no scripts, no code. The program is pure agent instructions.

---

## File Locations

| File | Purpose |
|---|---|
| `programs/session-ingestion/PROGRAM.md` | Generic agent genome |
| `programs/session-ingestion/HERALD.md` | Herald-specific variant |
| `references/session-ingestion-design.md` | This document |

The generic PROGRAM.md can be deployed as an OpenClaw cron payload directly, with
`AGENT_ID`, `WORKSPACE`, and `LOOKBACK_HOURS` set in the message body.

---

## Integration with Existing Memory System

Session ingestion is **additive** — it does not replace manual note-writing or the
nightly consolidation program. The data flow is:

```
Manual notes  ─┐
               ├──▶ memory/YYYY-MM-DD.md ──▶ Nightly Consolidation ──▶ MEMORY.md
Session ingest ─┘
```

The consolidation program (`programs/single-agent/PROGRAM.md`) already handles promotion
from daily notes to `MEMORY.md`, contradiction resolution, archival, and size enforcement.
Session ingestion simply ensures that daily notes contain facts even when manual note-writing
was missed.

---

## Known Limitations

- **Context window limits:** Very long sessions may need to be fetched in chunks. The program
  instructs agents to target the last 30–50 messages of long sessions.
- **Extraction quality:** An agent with a small context window or poor instruction-following
  may miss facts or over-extract noise. The write-conservatism rule ("when in doubt, discard")
  is the primary mitigation.
- **Session overlap:** When running every 4 hours, session boundaries may straddle run windows.
  The same session might be partially processed twice. Deduplication against the daily note
  prevents double-writes within a day, but cross-day session straddles are theoretically
  possible (and benign — the consolidator deduplicates against MEMORY.md).
- **No retroactive backfill:** The program operates within `LOOKBACK_HOURS`. Historical
  sessions beyond that window are not processed. A one-time backfill would require a manual
  run with a larger window.
