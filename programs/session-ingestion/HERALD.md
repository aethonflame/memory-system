# Session Ingestion Program — Herald Variant

This is the Herald-specific variant of the session ingestion program.
It extends the generic `PROGRAM.md` with Herald-specific parameters and extraction focus.

**Fixed parameters for Herald:**

| Variable | Value |
|---|---|
| `AGENT_ID` | `herald` |
| `WORKSPACE` | `/Users/aethon/clawd/agents/herald` |
| `LOOKBACK_HOURS` | `4` (scheduled); `1` (session-start) |

All other behaviour follows `PROGRAM.md` unless overridden below.

---

## Herald-Specific Memory Scope

Herald's memory is focused on its operational domain: news curation, source management,
preference learning, and digest quality. Extract only what improves Herald's future runs.

**Do extract:**
- Source quality signals (source X consistently over/under-delivers)
- Topic interest changes (Justin asked for more/less of X)
- Delivery feedback ("too many alerts", "missed Y story", "love the format")
- Operational issues discovered (source fetch failures, dedup gaps)
- New sources Justin mentioned or approved
- Breaking news threshold calibration signals
- Digest length / density preferences
- Story category preferences (AI > gaming, Singapore politics > routine crime)

**Do not extract for Herald:**
- Personal facts about Justin unrelated to news (goes to main agent's memory)
- Technical infrastructure changes unrelated to Herald's pipeline
- Anything about other agents' operations

---

## Step 1 — Discover Herald Sessions

Filter `sessions_list` results to sessions whose key contains `herald` or whose
agent binding matches the Herald bot agent.

Herald's sessions are typically short (cron runs: 3–5 min; chat: varies).
Most ingestion-worthy content comes from:
1. Chat sessions where Justin gave feedback on a digest or story
2. Chat sessions where Justin asked for more/less of a topic
3. Post-run sessions where Herald logged issues or anomalies

---

## Step 2 — Extraction Focus for Herald Sessions

When reading Herald session transcripts, pay special attention to:

### Preference Signals (high priority)
Explicit feedback on Herald's output is the highest-value content to extract:

```
"too many AI stories in a row" → Preferences: vary topic distribution across digest
"that Straits Times piece was exactly what I wanted" → Preferences: ST analysis/commentary tier 1
"why did I get three alerts today?" → Preferences: tighten breaking alert threshold
"the digest was too long" → Preferences: cap at 5 items, tighter summaries
```

### Source Quality Updates (Temporal Data)
If Herald discovered a source was unreliable, down, or degraded:

```
- **Reuters RSS intermittently returning 500s** _(as of YYYY-MM-DD)_
- **The Information paywalls 90% of content, low signal** _(as of YYYY-MM-DD)_
```

### Learned Patterns (Assistant Info)
Operational rules Herald discovered through experience:

```
- Always check X before Y in breaking scan
- Source Z fires duplicate items on Sundays — skip on Sunday runs
- Singapore parliamentary news clusters on Mondays/Tuesdays
```

### Interest Model Updates (Preferences)
Any shift in Justin's stated topic interests:

```
- Justin asked to deprioritize general crypto price news (keep protocol/research)
- Justin wants more Singapore macro / Budget coverage during Q1
- Gaming news elevated during game launch seasons if the title is relevant
```

---

## Step 3 — Deduplication for Herald

Read these files before writing:

1. `/Users/aethon/clawd/agents/herald/MEMORY.md` — Herald's long-term memory
2. `/Users/aethon/clawd/agents/herald/memory/YYYY-MM-DD.md` — today's daily note
3. `/Users/aethon/clawd/agents/herald/LEARNINGS.md` — Herald's operational rules

Skip any fact already captured in these files.

---

## Step 4 — Write to Herald's Daily Note

Write to `/Users/aethon/clawd/agents/herald/memory/YYYY-MM-DD.md`.

Use the standard ingestion block format from `PROGRAM.md`, but include a Herald-specific
context header so the consolidator knows this came from ingestion, not a live run:

```markdown
## [HH:MM] Session Ingestion — herald (LOOKBACK_HOURS h window)
_Source: session transcript extraction_

### Preferences
- [Justin feedback → preference delta]

### Temporal Data
- **[source/infrastructure state]** _(as of YYYY-MM-DD)_

### Assistant Info
- [operational rule or learned pattern]
```

---

## Step 5 — Run Log for Herald

Write to `/Users/aethon/clawd/agents/herald/memory-system/runs/ingestion-YYYY-MM-DD.md`
(create if absent).

Same format as `PROGRAM.md` Step 6, with `AGENT_ID=herald`.

---

## Herald-Specific NEVER DO

In addition to the standard NEVER DO list:

- Never update `sources.json`, `ledger-seen.json`, or `ledger-runs.json` — those are
  Herald's live operational state, not memory
- Never modify `feeds/` directory files from ingestion
- Never infer topic changes from a single data point — preferences need ≥2 signals or
  an explicit statement before being written
- Never write Justin's personal/life facts here — route those to main agent memory instead

---

## After You're Done

Reply with: `INGESTION_COMPLETE`

One-line summary: sessions processed, preference deltas extracted, source signals captured,
contradictions flagged.
