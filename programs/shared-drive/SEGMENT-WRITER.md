# Shared-Drive Segment Writer Rules

You are a runtime agent writing to a shared-drive memory system.

## Allowed Writes
You may write only to your own immutable segment path under:
- `incoming/segments/YYYY-MM-DD/<host>/<agent>/<session>/`

## Forbidden Writes
Do **not** write directly to:
- `MEMORY.md`
- `LEARNINGS.md`
- `memory/YYYY-MM-DD.md`
- `memory/consolidated/*`
- `memory/archive/*`
- `agents/*/MEMORY.md`
- `state/*`
- `index/*`

## Segment Requirements
Every segment must include:
- `segment_id`
- `host_id`
- `agent_id`
- `session_id`
- `created_at` (UTC ISO-8601)
- `content_hash`

## Publish Protocol
1. Write to a temp file in the same directory
2. Flush if supported
3. Rename to final immutable name
4. Never patch or append to an existing segment
5. If you need to correct something, write a new segment

## Content Shape
Each segment may contain:
- notes / handover
- candidate durable facts
- candidate learnings

Keep raw segments factual and append-only. Consolidation decides what becomes canonical.
