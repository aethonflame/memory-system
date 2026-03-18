# Shared-Drive Indexer Policy

## Core Rule
Do **not** use one live writable shared QMD/search index across multiple hosts.

## Recommended Modes
1. **Best default:** local per-host indexes built from canonical shared markdown
2. **Optional:** one designated host publishes immutable index snapshots; readers consume snapshots read-only

## Index Inputs
Index only canonical files:
- `MEMORY.md`
- `LEARNINGS.md`
- `memory/YYYY-MM-DD.md`
- `memory/consolidated/*`
- `agents/*/MEMORY.md`

Do not index temp files or in-flight raw segment temp artifacts.

## Publication Rules
- Build indexes on local disk
- Publish snapshot directories as immutable generations
- Update `index/CURRENT` only after the full snapshot is ready
- Never mutate a published generation in place
