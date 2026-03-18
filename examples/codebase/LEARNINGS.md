# LEARNINGS.md — Example Codebase

## This Codebase
- Never edit historical pricing rules in place — create a new version
- Always run contract tests before changing response schema

## Deployment
- Staging and prod use different Redis DB numbers — verify before debugging cache issues
