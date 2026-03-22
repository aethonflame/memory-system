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

- `MEMORY.md` — curated long-term facts
- `LEARNINGS.md` — rules distilled from mistakes
- `memory/YYYY-MM-DD.md` daily logs
- consolidation / eval / prune scripts
- a `PROGRAM.md` genome for the consolidator
- optional shared-drive programs for multi-agent segment writing and publication
- examples and reference material

## When to use which mode

### single-agent
Use for one agent operating in one workspace.

### codebase
Use for a project repo where the agent needs memory about architecture, decisions, gotchas, and handovers.

### shared-drive
Use when many concurrent agents may write raw observations, but one designated consolidator must publish canonical memory and index generations.

## Boot instructions to add to your agent

At session start, read:
1. `MEMORY.md`
2. `learnings/LEARNINGS.md`
3. today's and yesterday's `memory/YYYY-MM-DD.md`

During tasks:
- write raw notes to today's daily log
- never write directly to `MEMORY.md`
- add durable operational rules to `LEARNINGS.md`
- use nightly consolidation to promote facts into long-term memory

## Shared-drive rule

If using `shared-drive` mode, runtime agents must follow `programs/shared-drive/SEGMENT-WRITER.md`.
Canonical files are single-writer only.

## References

- `references/write-discipline.md`
- `references/learnings-examples.md`
- `references/ground-truth-guide.md`
- `references/program-md-guide.md`
- `references/shared-drive-multi-agent-design.md`
- `references/memory-org-standards.md` — naming conventions, directory structure, content tiers, when to create new sections
