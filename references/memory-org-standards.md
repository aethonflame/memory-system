# Memory Organisation Standards

Guidelines for naming and structuring files under `~/clawd/memory/`.
Follow these when creating new memory sections or files.

---

## Directory Structure

```
memory/
├── YYYY-MM-DD.md          # daily session notes (auto-created by consolidation)
├── metrics/               # eval scores, dashboard, run logs
├── private/               # vault-gated sensitive notes (TOTP-protected)
│   └── projects/          # per-project private notes
├── external/              # memory from external agents (read-only for main)
│   └── gamedev/           # Jaison/game-dev context
└── shopping/              # product preferences, wish lists, purchase history
    └── preferences.md     # switches, layouts, brands, buying style
```

---

## Naming Standards

### Files
- **Daily notes:** `YYYY-MM-DD.md` — always ISO date, no exceptions
- **Topic files:** `kebab-case.md` — lowercase, hyphens, no spaces
- **No generic names at root level** — e.g. `preferences.md` at `memory/` root is too vague; put it in a subdirectory

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
|---------|----------|
| Long-term facts, project state, preferences | `MEMORY.md` (top-level, shareable) |
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
