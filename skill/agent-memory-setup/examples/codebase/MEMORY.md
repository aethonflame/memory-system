# MEMORY.md — Example Codebase Memory

## Project Overview
- **Name:** Internal pricing service
- **Stack:** Python, FastAPI, Redis, PostgreSQL
- **Purpose:** Calculate and expose pricing rules for downstream systems

## Key Decisions
- Pricing rules are versioned and immutable once published
- Redis is cache only; canonical state is Postgres
- All migrations require dry-run output before apply

## People & Roles
- Priya — product owner
- Daniel — infra / deployment
