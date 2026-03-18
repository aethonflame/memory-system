# MEMORY.md — Example Single-Agent Workspace

## Project Overview
- **Name:** Chat inbox assistant
- **Stack:** Next.js, FastAPI, PostgreSQL
- **Purpose:** Help customer support respond faster with memory-backed context

## Key Decisions
- Use Postgres for canonical app state
- Use markdown memory for agent continuity, not transactional business data
- Consolidate daily notes nightly at 03:00 local time

## Conventions
- Never write directly to MEMORY.md during tasks
- Every meaningful mistake becomes a LEARNINGS.md rule
