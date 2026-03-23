# Memory Organisation Standards

Guidelines for naming and structuring files under `~/clawd/memory/` (or equivalent workspace root).
Follow these when creating new memory sections or files.

---

## MEMORY.md Six-Vector Structure

`MEMORY.md` is the canonical long-term memory file. It uses a **six-vector structure** so agents can
retrieve from the right section intelligently rather than scanning the whole file.

### Personal Memory Mode

| # | Section | What goes here |
|---|---|---|
| 1 | **Personal Info** | Who the person is: name, role, location, background, relationships |
| 2 | **Preferences** | Explicit likes/dislikes, working style, habits, stated preferences |
| 3 | **Events** | Things that happened: milestones, decisions, incidents, context |
| 4 | **Temporal Data** | Time-sensitive facts — every entry has `_(as of YYYY-MM-DD)_` |
| 5 | **Updates** | Corrections/supersessions of old facts — **never delete these** |
| 6 | **Assistant Info** | What the agent has learned about itself: config, rules, session behaviour |

### Codebase Memory Mode

Same structure, relabelled for technical context:

| # | Section | What goes here |
|---|---|---|
| 1 | **Project Overview** | What is this, who built it, why, key stakeholders |
| 2 | **Architecture Decisions** | Patterns we follow, things we avoid, key technical choices + rationale |
| 3 | **Milestones** | Phases completed, major refactors, deployments, handovers |
| 4 | **Current State** | What's live, broken, pending — every entry has `_(as of YYYY-MM-DD)_` |
| 5 | **Decision Changes** | When we reversed a decision and why — **never delete these** |
| 6 | **Agent Notes** | What the coding agent has learned: gotchas, setup quirks, non-obvious behaviour |

### Temporal Data Format

Time-sensitive entries (sections 4 and 5) must include an `as of` date:

```markdown
- **[fact]** _(as of YYYY-MM-DD)_
```

### Updates / Decision Changes Format

Corrections and supersessions use an extended format:

```markdown
- **[new fact]** _(as of YYYY-MM-DD, supersedes: [old fact])_
```

These entries are **permanent** — never prune the Updates section.

---

## Directory Structure

```
memory/
├── YYYY-MM-DD.md          # daily session notes (auto-created)
├── consolidated/          # monthly rollups (auto-created by consolidation)
│   └── YYYY-MM.md
├── archive/               # cold storage — monthly rollups older than 6 months
│   └── YYYY-MM.md
├── metrics/               # eval scores, dashboard, run logs
├── private/               # vault-gated sensitive notes (TOTP-protected)
│   └── projects/          # per-project private notes
├── external/              # memory from external agents (read-only for main)
│   └── <agent-name>/
└── shopping/              # product preferences, wish lists, purchase history
    └── preferences.md
```

---

## Naming Standards

### Files
- **Daily notes:** `YYYY-MM-DD.md` — always ISO date, no exceptions
- **Topic files:** `kebab-case.md` — lowercase, hyphens, no spaces
- **No generic names at root level** — e.g. `preferences.md` at `memory/` root is too vague; use a subdirectory

### Directories
- **Purpose-named, singular or plural as natural English dictates**
  - `shopping/` not `shop/` or `purchases/`
  - `private/` not `secrets/`
  - `external/` not `ext/`
- **One level of nesting preferred** — avoid deep trees
- **New section checklist:**
  1. Does a parent directory already exist that fits? Use it.
  2. Is the topic broad enough to warrant its own directory? (>1 file likely, or clearly distinct domain)
  3. Name it after the domain, not the agent or date

---

## Content Standards

### What goes where

| Content | Location |
|---|---|
| Long-term facts, preferences, project state | `MEMORY.md` (six-vector sections) |
| Sensitive details, credentials hints | `memory/private/` (vault-gated) |
| Daily session notes | `memory/YYYY-MM-DD.md` |
| Shopping/product preferences | `memory/shopping/preferences.md` |
| Eval metrics | `memory/metrics/` |
| External agent context | `memory/external/<agent-name>/` |

### Tier discipline
- `MEMORY.md` — **shareable tier only** — no secrets, no credentials, nothing you wouldn't show a colleague
- `memory/private/` — sensitive tier, TOTP-gated via vault
- Never put secrets or API keys in plain markdown files, even in `private/`

---

## Retrieval

For instructions on how to query MEMORY.md intelligently at runtime, see:
**`references/RETRIEVAL.md`** — three-path agentic retrieval guide (no vector DB required)

---

## When to Create a New Section

Create a new subdirectory when:
- There are (or will be) multiple files on the same topic
- The topic is clearly distinct from existing sections
- The content doesn't naturally fit in MEMORY.md or a daily note

Do not create a new subdirectory for:
- A single one-off file that fits in an existing section
- Something that belongs in MEMORY.md directly
- Temporary notes (use daily notes instead)

---

## Evolution

This document is the source of truth for memory org standards.
Update it when new sections are created or conventions change.
The consolidation agent should reference this when deciding where to write new content.
