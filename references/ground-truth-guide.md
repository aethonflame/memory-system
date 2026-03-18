# Ground Truth Query Guide

How to write good eval queries for `memory-system/ground-truth.json`.

---

## What Makes a Good Query

**Good:** Natural language, something the agent would actually be asked
```json
{ "query": "What database does this project use?", "expected_keywords": ["postgres"] }
```

**Bad:** Too specific, only matches exact phrasing
```json
{ "query": "PostgreSQL version 17", "expected_keywords": ["PostgreSQL version 17"] }
```

**Bad:** Too vague, hard to define expected answer
```json
{ "query": "How does this work?", "expected_keywords": ["works"] }
```

## Coverage Targets

Aim for 15–20 queries covering:

| Category | Examples |
|----------|---------|
| Project basics | Purpose, stack, team |
| Architecture | Key decisions, services, data flow |
| Conventions | Code style, naming, patterns |
| Operations | Deploy process, environments, credentials location |
| People | Who to ask about X, contact info |
| History | Why was X decided, what did we try before |
| Gotchas | Known pitfalls, non-obvious behaviour |

## Expected Keywords

- Use 2–4 keywords per query
- Keywords should be unique enough to confirm the right answer was found
- Avoid stop words (the, a, is, was)
- Include both the concept and specific terms

```json
{
  "query": "How do we handle authentication?",
  "expected_keywords": ["JWT", "auth", "token"],
  "source": "MEMORY.md"
}
```

## Recall vs Precision

The eval script tests **recall** — did the right answer appear in results?

A score of 0.70+ on natural language queries indicates a healthy memory system.
Below 0.50 usually means:
- MEMORY.md doesn't contain the answer yet (add it)
- Vector embeddings not yet generated (run `qmd embed`)
- Queries too abstract for keyword search (add more specific facts to MEMORY.md)

## Updating Over Time

Add new queries whenever you add significant content to MEMORY.md.
Remove queries when the content they test becomes stale.
Target: 15–25 queries. More than 30 is overhead without much signal gain.
