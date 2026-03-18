# memory-system

A reusable memory framework for agent workspaces.

## Modes

- **single-agent** — one agent, one workspace, canonical markdown memory files
- **codebase** — same scaffold, framed for a project repo
- **shared-drive** — many agents write immutable raw segments, one consolidator publishes canonical memory

## Quick start

Interactive by default:

```bash
bash scripts/setup.sh
```

Explicit mode:

```bash
bash scripts/setup.sh --mode single-agent --path /path/to/workspace
bash scripts/setup.sh --mode codebase --path /path/to/repo
bash scripts/setup.sh --mode shared-drive --path /path/to/shared-root
```

## Non-interactive mode

Supplying `--mode` makes setup non-interactive.
If `--path` is omitted, setup defaults to the current directory.

## Layout

```text
memory-system/
├── templates/      # starter files for MEMORY.md, LEARNINGS.md, daily notes, shared segments
├── scripts/        # setup, consolidate, eval, prune, package-skill
├── programs/       # agent instructions / genomes
├── references/     # design docs and operational guides
├── skill/          # exportable OpenClaw skill source
├── dist/           # packaged skill artifacts (generated)
└── examples/       # example outputs for each mode
```

## Packaging the OpenClaw skill

Build the `.skill` artifact directly from the repo:

```bash
bash scripts/package-skill.sh
```

Output:
- source skill dir: `skill/agent-memory-setup/`
- packaged artifact: `dist/agent-memory-setup.skill`

## Design principles

- Raw runtime capture and curated long-term memory are separate concerns
- `MEMORY.md` is curated; daily logs are append-only
- `LEARNINGS.md` compounds agent improvement from mistakes
- Consolidation and promotion happen on a cadence, not inline with task work
- Shared-drive safety comes from append-only raw writes + single-writer publication
