# Write Discipline — Agent Instructions

Copy these rules into your agent's system prompt or AGENTS.md.

---

## After Every Significant Task

Append to `memory/YYYY-MM-DD.md`:
```markdown
## [HH:MM] Task: <brief description>
- **Decision:** what was decided and why
- **Outcome:** what happened
- **Blocker/learning:** anything worth remembering
```

## After Every Mistake

Append one line to `learnings/LEARNINGS.md`:
```
- Never X without Y
- Always check Z when W happens
- If you see error E, the cause is usually C
```

## Never Write Directly to MEMORY.md During Tasks

- Daily logs are raw and append-only
- MEMORY.md is curated long-term memory
- Consolidation promotes facts from daily logs to MEMORY.md nightly
- Writing uncurated noise to MEMORY.md bloats it into uselessness within weeks

## Handover Before Model Switch or Session End

Write a HANDOVER section to today's daily log:
```markdown
## HANDOVER — HH:MM
- **What was discussed:** ...
- **Decisions made:** ...
- **Pending tasks:** ... (with exact details, file paths, line numbers if relevant)
- **Next steps:** ...
```

## Retrieval — When to Search

Proactively search memory when:
- A person is mentioned → search for their history
- Continuing a task → search daily logs for prior context
- Something "feels familiar" → check if you've seen it before
- About to make a decision → check if this was already decided

## Size Limits

| File | Target | Hard cap |
|------|--------|----------|
| MEMORY.md | ≤ 150 lines | 400 lines |
| learnings/LEARNINGS.md | ≤ 100 lines | 200 lines |
