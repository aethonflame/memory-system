# RETRIEVAL.md — Agentic Memory Retrieval Guide

How to query MEMORY.md intelligently when answering questions about prior context.
Load this document when `memory_search` is unavailable or returns insufficient results.

---

## The Problem with Free-Form Memory

Scanning an entire MEMORY.md looking for a keyword is unreliable.
You miss implications, find stale facts, and don't reconstruct the full picture.

The six-vector structure solves this by routing queries to the right section first.

---

## Three-Path Retrieval

For any question about prior context, run all three paths and synthesise:

### Path 1 — Direct Facts (Personal Info / Preferences / Project Overview / Architecture)
_Use when:_ the question is about who someone is, what they prefer, or how the system is designed.

1. Read the **Personal Info** (or **Project Overview** for codebase) section
2. Read the **Preferences** (or **Architecture Decisions**) section
3. Look for an exact match first; if not found, look for an implicit one

Examples:
- "Does Alex prefer self-hosted tools?" → check Preferences
- "Who owns the pricing service?" → check Project Overview
- "What's the API versioning strategy?" → check Architecture Decisions

---

### Path 2 — Context & Implications (Events / Milestones)
_Use when:_ the question asks why something is the way it is, what happened, or what the history is.

1. Read the **Events** (or **Milestones**) section
2. Look for entries that explain decisions, turning points, or context
3. Events often contain the *why* behind facts in other sections

Examples:
- "Why did we switch to URL-path versioning?" → check Decision Changes + Milestones
- "What happened with the API key incident?" → check Events
- "When did Phase 1 ship?" → check Milestones

---

### Path 3 — Temporal Reconstruction (Temporal Data + Updates)
_Use when:_ the question is about current state, or when you suspect a fact may be stale.

1. Read the **Temporal Data** (or **Current State**) section — these have `as of` dates
2. Read the **Updates** (or **Decision Changes**) section — these are the correction log
3. Combine: find the most recent version of the fact by tracing supersession chains
4. If a fact in Temporal Data is old and there's a matching Update entry, use the Update

Examples:
- "What Postgres cluster is active?" → check Temporal Data (port, path) + Updates (any supersessions)
- "Is the bulk pricing bug fixed?" → check Current State + Decision Changes
- "What model is Aethon using for Telegram DMs?" → check Temporal Data + Updates

---

## Supersession Tracing

When you find a fact with `_(as of YYYY-MM-DD, supersedes: ...)_`:

1. The entry in **Updates** is the **current truth**
2. The superseded value is **historical** — do not use it as current fact
3. If multiple Update entries exist for the same fact, use the most recent one

**Example chain:**
```
Temporal Data:
  Postgres port: 5432 (as of 2024-01-01)

Updates:
  Postgres port: 5433 (as of 2026-03-15, supersedes: 5432 — original cluster had permission issue)
```
→ Current answer: **port 5433**

---

## When Memory Is Insufficient

If all three paths fail to answer the question:

1. Check daily notes (`memory/YYYY-MM-DD.md`) for recent context — go back up to 7 days
2. Check consolidated notes (`memory/consolidated/YYYY-MM.md`) for older context
3. If still uncertain, **say so explicitly** — don't confabulate from partial context

---

## Routing Quick Reference

| Question type | Start here |
|---|---|
| Who is this person? What do they do? | Personal Info |
| What are their preferences / working style? | Preferences |
| What happened? Why did X occur? | Events |
| Is this fact still current? | Temporal Data → Updates |
| What's the current state of [project/system]? | Temporal Data |
| What was changed / reversed? | Updates / Decision Changes |
| What is this codebase? Who built it? | Project Overview |
| What patterns do we follow? What do we avoid? | Architecture Decisions |
| What did the agent learn about this repo? | Agent Notes |

---

## Memory Write Discipline (reminder)

- **Never write directly to MEMORY.md during a task** — write to today's daily note
- **Only the consolidation program** promotes facts to MEMORY.md
- **Always include `as of YYYY-MM-DD`** for time-sensitive facts when writing daily notes
- **When you find a contradiction**, note the old value explicitly so the consolidator can create an Update entry
