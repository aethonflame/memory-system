# MEMORY.md — Example Codebase Memory
# Curated facts only. Never write here directly during tasks.
# Updated by the consolidation program.

---

## 1. Project Overview
- **Name:** Internal Pricing Service
- **Stack:** Python 3.12, FastAPI, Redis 7, PostgreSQL 16
- **Purpose:** Calculate and expose pricing rules for downstream billing systems
- **Repo:** github.com/acme/pricing-service (private)
- **Owner:** Priya (product), Daniel (infra), Alex (backend lead)
- **Started:** 2024-Q3 | **Status:** production

---

## 2. Architecture Decisions
- Pricing rules are versioned and immutable once published — rollback by activating an older version
- Redis is cache only; canonical state is always Postgres — no Redis-first writes
- All DB migrations require `make migrate-dry` output before `make migrate` — team rule
- Never use ORM for complex queries — raw SQL with typed result sets
- API versioning: URL-path versioned (/v1/, /v2/) — header versioning rejected for client complexity

---

## 3. Milestones
- **2024-Q3:** Initial pricing engine + REST API shipped to staging
- **2024-Q4:** Redis caching layer added — reduced p99 latency from 800ms → 45ms
- **2025-02:** v2 API launched — v1 deprecated (sunset 2025-08)
- **2025-06:** Handed over infra ownership to Daniel; Alex moved to new project

---

## 4. Current State
- **v2 API in production; v1 still serving (sunset in 2 months)** _(as of 2025-06-01)_
- **Known bug: bulk pricing endpoint times out for >500 SKUs** _(as of 2025-06-15)_
- **Pending: Redis 6 → Redis 7 migration (blocked on infra approval)** _(as of 2025-06-20)_
- **CI: GitHub Actions, all green** _(as of 2025-07-01)_

---

## 5. Decision Changes
- **Switched to URL-path API versioning** _(as of 2025-01-10, supersedes: header-based versioning — rejected for client complexity)_
- **Redis now cache-only; removed Redis-first write pattern** _(as of 2024-11-05, supersedes: dual-write approach — caused consistency bugs)_
- **Migrated from SQLAlchemy ORM to raw SQL** _(as of 2025-03-12, supersedes: ORM-first approach — performance and debugging issues on complex queries)_

---

## 6. Agent Notes
- Always run `make migrate-dry` before `make migrate` — no exceptions
- Test suite requires `PRICING_TEST_DB` env var; falls back to 'pricing_test' (may not exist locally)
- The `rules_engine/` module is the oldest code — minimal tests, handle carefully
- Local dev: `docker-compose up` starts all deps; `make dev` runs the app with hot-reload
- Deployment: PRs auto-deploy to staging; prod deploy requires manual approval in GitHub Actions
