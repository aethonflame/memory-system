---
name: agent-memory-setup
description: Set up a reusable agent memory framework for a single workspace, a codebase, or a shared multi-agent drive. Use when bootstrapping persistent memory for Claude/OpenClaw-style agents, adding LEARNINGS.md and daily logs to a project, or preparing a shared-drive memory root with single-writer consolidation. Triggers on phrases like "set up agent memory", "memory scaffold", "add LEARNINGS.md", "persistent memory for this repo", "shared-drive agent memory", or "package the memory system as a skill".
---

# Agent Memory Setup

Scaffold the memory-system framework into a target workspace.

## Supported modes

```bash
bash scripts/setup.sh
```

If `--mode` is omitted, setup is **interactive by default**.

Explicit modes:

```bash
bash scripts/setup.sh --mode single-agent --path /path/to/workspace
bash scripts/setup.sh --mode codebase --path /path/to/repo
bash scripts/setup.sh --mode shared-drive --path /path/to/shared-root
```

Supplying `--mode` disables prompts. If `--path` is omitted, setup defaults to the current directory.

## What this skill provides

- `MEMORY.md` — curated long-term facts (six-vector structure)
- `LEARNINGS.md` — rules distilled from mistakes
- `memory/YYYY-MM-DD.md` daily logs
- consolidation / eval / prune scripts
- a `PROGRAM.md` genome for the consolidator
- optional shared-drive programs for multi-agent segment writing and publication
- examples and reference material

## Six-Vector Memory Structure

MEMORY.md uses a structured six-vector layout so agents can retrieve from the right
section intelligently, rather than scanning the entire file. No vector DB required.

### Personal / workspace mode

| # | Section | What goes here |
|---|---|---|
| 1 | **Personal Info** | Who the person is: name, role, location, relationships |
| 2 | **Preferences** | Working style, habits, explicit likes/dislikes |
| 3 | **Events** | Milestones, decisions, incidents, context |
| 4 | **Temporal Data** | Time-sensitive facts with `_(as of YYYY-MM-DD)_` |
| 5 | **Updates** | Corrections/supersessions — permanent change log, never delete |
| 6 | **Assistant Info** | Agent config, operational rules, session behaviour |

### Codebase mode (relabelled same structure)

| # | Section | What goes here |
|---|---|---|
| 1 | **Project Overview** | What is this, who built it, why |
| 2 | **Architecture Decisions** | Patterns followed, things avoided, key choices + rationale |
| 3 | **Milestones** | Phases completed, deployments, major refactors |
| 4 | **Current State** | Live/broken/pending — always with `_(as of YYYY-MM-DD)_` |
| 5 | **Decision Changes** | Reversed decisions and why — permanent, never delete |
| 6 | **Agent Notes** | Coding agent's learnings: gotchas, quirks, non-obvious behaviour |

**Stale fact detection:** The consolidation program detects contradictions and creates an
`Updates` entry (format: `**[new fact]** _(as of YYYY-MM-DD, supersedes: [old fact])_`)
instead of silently overwriting. Updates entries are permanent — they're the change log.

## When to use which mode

### single-agent
Use for one agent operating in one workspace (personal memory, assistant context).

### codebase
Use for a project repo where the agent needs memory about architecture, decisions, gotchas, and handovers.

### shared-drive
Use when many concurrent agents may write raw observations, but one designated consolidator must publish canonical memory and index generations.

## Boot instructions to add to your agent

At session start, read:
1. `MEMORY.md` — long-term curated facts (all six sections)
2. `learnings/LEARNINGS.md` — operational rules
3. Today's and yesterday's `memory/YYYY-MM-DD.md` — recent context

During tasks:
- Write raw notes to today's daily log
- Never write directly to `MEMORY.md`
- Add durable operational rules to `LEARNINGS.md`
- Use nightly consolidation to promote facts into long-term memory

## Retrieval at query time

When answering questions about prior context, load `references/RETRIEVAL.md` for the
three-path retrieval guide:
1. **Direct facts** — check Personal Info / Preferences for exact matches
2. **Context & implications** — check Events for history and rationale
3. **Temporal reconstruction** — check Temporal Data + Updates to get the current version of a fact

This replaces "scan the whole file and hope" with section-targeted reads.

## Shared-drive rule

If using `shared-drive` mode, runtime agents must follow `programs/shared-drive/SEGMENT-WRITER.md`.
Canonical files are single-writer only.

## References

- `references/RETRIEVAL.md` — **three-path agentic retrieval guide** (load when memory_search is insufficient)
- `references/write-discipline.md`
- `references/learnings-examples.md`
- `references/ground-truth-guide.md`
- `references/program-md-guide.md`
- `references/shared-drive-multi-agent-design.md`
- `references/memory-org-standards.md` — naming conventions, directory structure, six-vector details, content tiers
