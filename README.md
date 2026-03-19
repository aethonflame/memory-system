# memory-system

A reusable memory framework for agent workspaces.

It gives an agent somewhere durable to put:
- daily notes
- learned rules (`LEARNINGS.md`)
- curated long-term memory (`MEMORY.md`)
- consolidation logic
- evaluation queries
- shared-drive patterns for multi-agent setups

The goal is simple: **stop relying on the context window as memory**.

---

## What problem this solves

Most agents can reason well, but they forget.

Without a memory pattern, important things stay trapped in the conversation:
- architecture decisions
- user preferences
- recurring mistakes
- project state
- handover context between sessions or models

`memory-system` turns that into files and routines an agent can actually use:
- **daily logs** for raw notes
- **LEARNINGS.md** for distilled rules from mistakes
- **MEMORY.md** for curated long-term facts
- **nightly consolidation** to promote what matters and prune what doesn't
- **evaluation** so memory quality can be measured instead of assumed

---

## Modes

### 1. `single-agent`
Use when one agent operates in one workspace.

### 2. `codebase`
Use when you want a repo to accumulate memory about:
- architecture
- conventions
- decisions
- gotchas
- handovers

### 3. `shared-drive`
Use when multiple concurrent agents need to share memory safely.

In this mode:
- many agents write **immutable raw segments**
- one consolidator host publishes **canonical memory**
- shared markdown files are **single-writer only**

---

## Quick start

### Interactive

```bash
bash scripts/setup.sh
```

If you omit `--mode`, setup is interactive.

### Explicit / non-interactive

```bash
bash scripts/setup.sh --mode single-agent --path /path/to/workspace
bash scripts/setup.sh --mode codebase --path /path/to/repo
bash scripts/setup.sh --mode shared-drive --path /path/to/shared-root
```

If `--mode` is supplied:
- setup becomes non-interactive
- `--path` is optional
- if `--path` is omitted, the current directory is used

Example:

```bash
cd ~/code/my-project
bash /path/to/memory-system/scripts/setup.sh --mode codebase
```

---

## What gets created

For single-agent / codebase mode, the scaffold creates this shape inside the target:

```text
<workspace>/
├── MEMORY.md
├── LEARNINGS.md
├── memory/
│   ├── YYYY-MM-DD.md
│   ├── consolidated/
│   ├── archive/
│   └── metrics/
├── learnings/
│   └── LEARNINGS.md
└── memory-system/
    ├── PROGRAM.md
    ├── ground-truth.json
    ├── consolidate.sh
    ├── eval.sh
    └── prune.sh
```

For shared-drive mode, it also creates:
- `incoming/segments/`
- `state/`
- `index/`
- shared-drive program files

---

## Recommended operating model

### During work
- write raw notes to `memory/YYYY-MM-DD.md`
- never dump everything straight into `MEMORY.md`
- turn repeated mistakes into short rules in `LEARNINGS.md`

### On consolidation
- promote durable facts into `MEMORY.md`
- promote durable rules into `LEARNINGS.md`
- roll up old daily notes
- archive stale history

### On evaluation
- run ground-truth queries against the memory corpus
- track whether recall is improving or degrading

---

## Shared-drive recommendation

If you're using multiple concurrent agents on a network drive, the recommended pattern is:

- **many writers** → raw immutable segment files only
- **one writer** → canonical memory publication

Do **not** let multiple agents patch the same `MEMORY.md`, `LEARNINGS.md`, or daily markdown files live.

See:
- `references/shared-drive-multi-agent-design.md`
- `programs/shared-drive/SEGMENT-WRITER.md`
- `programs/shared-drive/PROGRAM.md`

---

## Repository layout

```text
memory-system/
├── templates/      # starter files for MEMORY.md, LEARNINGS.md, daily notes, shared segments
├── scripts/        # setup, consolidate, eval, prune, package-skill
├── programs/       # agent instructions / genomes
├── references/     # design docs and operational guides
├── examples/       # example outputs for each mode
├── skill/          # exportable OpenClaw skill source
└── dist/           # packaged skill artifacts (generated)
```

### Important directories

- `templates/` — the actual scaffold inputs
- `programs/` — the agent-facing operating instructions
- `references/` — design docs and deeper guidance
- `examples/` — concrete reference outputs
- `skill/agent-memory-setup/` — packaged-skill source derived from this repo

---

## Packaging the OpenClaw skill

This repo can emit a `.skill` artifact directly:

```bash
bash scripts/package-skill.sh
```

Output:
- source skill dir: `skill/agent-memory-setup/`
- packaged artifact: `dist/agent-memory-setup.skill`

---

## Migration note

`agent-memory-setup` is now deprecated in favour of this repo.

Use `memory-system` as the source of truth.
Treat the skill packaging flow as a distribution artifact, not the main project.

---

## Design principles

- Raw runtime capture and curated long-term memory are different jobs
- `MEMORY.md` is curated; daily logs are append-only
- `LEARNINGS.md` compounds improvement from mistakes
- Consolidation and promotion happen on a cadence, not inline with task work
- Shared-drive safety comes from append-only raw writes + single-writer publication
- Boring, robust designs beat clever distributed-systems magic for memory infrastructure
