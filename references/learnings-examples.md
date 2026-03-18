# LEARNINGS.md Examples by Domain

Seed your LEARNINGS.md with rules relevant to your stack.
Copy what applies, delete what doesn't.

---

## Git

- Never claim code is pushed without running `git status` first
- Always check the branch before committing — verify you're not on main
- If a PR looks merged but isn't in prod, check if the deploy pipeline ran
- Squash commits before merging to keep history clean

## Python

- Always activate venv before running tests: `source venv/bin/activate`
- Never import from `__init__.py` in tests — causes circular imports
- Use `python -m pytest` not `pytest` to ensure the right environment
- Type hints on function signatures save 20 minutes of debugging per session

## JavaScript / TypeScript

- `undefined` and `null` are different — check both when validating inputs
- `await` inside a `forEach` does not work as expected — use `for...of`
- Always check `package.json` engines field before upgrading Node
- TypeScript strict mode catches real bugs — don't disable it

## SQL / PostgreSQL

- Always test migrations with `--dry-run` before applying to prod
- `DELETE` without `WHERE` is irreversible — double-check before running
- Use `EXPLAIN ANALYZE` before optimising — assumptions about slow queries are often wrong
- Index on foreign keys — Postgres doesn't do this automatically

## Docker

- Tag images explicitly — `latest` is ambiguous across environments
- `docker-compose down -v` removes volumes — data loss if DB is in a volume
- Build args are not secrets — use runtime env vars for credentials

## API Development

- Always validate input before processing — never trust client data
- Return consistent error shapes — include `code`, `message`, and `details`
- Rate limit before auth check — avoid leaking whether an account exists
- Version your API from day one — retrofitting versioning is painful

## Testing

- Test the behaviour, not the implementation — tests that break on refactor are noise
- If a test is flaky, fix it now — it will hide real failures later
- Seed test data explicitly — don't depend on prod data or test ordering
- One assertion per test where possible — easier to diagnose failures

## Deployment

- Never deploy on Friday afternoon
- Always check logs immediately after deploy — don't walk away
- Feature flags let you decouple deploy from release — use them
- Rollback plan must exist before you deploy, not after

## Agent-Specific

- If memory_search returns nothing, check if the index is stale — try a keyword query
- Don't write session-specific troubleshooting to MEMORY.md — it's noise
- If the agent makes the same mistake twice, that's a LEARNINGS.md entry
- Test retrieval explicitly after adding new memory — storage ≠ retrieval
