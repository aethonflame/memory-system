# OpenClaw Hooks Research

_Researched: 2026-03-24 | OpenClaw version: 2026.3.13_

---

## What Hooks Are

Hooks are TypeScript functions that run inside the Gateway when agent events fire. They are:
- Discovered automatically from `<workspace>/hooks/`, `~/.openclaw/hooks/`, and bundled dirs
- Managed via `openclaw hooks {list,enable,disable,info}`
- Configured in `openclaw.json` under `hooks.internal.entries.<name>.enabled`

Each hook is a directory with `HOOK.md` (metadata) and `handler.ts` (implementation).

---

## The session-memory Hook

**Purpose:** Save session context to memory when `/new` is issued.

**Event:** `command:new` — fires only when the user explicitly issues the `/new` command.

**What it does:**
1. Locates the pre-reset session transcript
2. Extracts the last 15 lines of conversation
3. Uses LLM to generate a descriptive filename slug
4. Writes `<workspace>/memory/YYYY-MM-DD-slug.md`

**Output location:** `<clawd workspace>/memory/YYYY-MM-DD-slug.md` (defaults to `~/.openclaw/workspace/memory/`)

**Example files created:** `2026-03-17-1620.md`, `2026-03-17-session-start.md`

**Current config:**
```json
"session-memory": { "enabled": true }
```

**Limitation:** This hook fires only on explicit `/new`. It does NOT fire on:
- Gateway restart
- New channel conversations starting
- First message after idle period
- Any automatic session rotation

---

## Available Hook Events (v2026.3.13)

### Currently Available
| Event | When it fires |
|---|---|
| `command:new` | User issues `/new` |
| `command:reset` | User issues `/reset` |
| `command:stop` | User issues `/stop` |
| `command` | Any command |
| `agent:bootstrap` | Before workspace bootstrap files injected |
| `gateway:startup` | After channels start, hooks loaded |
| `message:received` | Inbound message arrives (before media processing) |
| `message:transcribed` | After audio transcription completes |
| `message:preprocessed` | After all media/link understanding |
| `message:sent` | Outbound message successfully sent |
| `session:compact:before` | Before compaction summarises history |
| `session:compact:after` | After compaction completes |

### NOT Available Yet (Planned)
```
session:start    ← When a new session begins  (PLANNED, not implemented)
session:end      ← When a session ends         (PLANNED, not implemented)
agent:error      ← When an agent errors        (PLANNED, not implemented)
```

The `session:start` event would be perfect for this use case but **does not exist yet**.

---

## Other Bundled Hooks

| Hook | Event | Purpose |
|---|---|---|
| `bootstrap-extra-files` | `agent:bootstrap` | Inject extra workspace files during bootstrap |
| `command-logger` | `command` | Log all commands to `~/.openclaw/logs/commands.log` |
| `boot-md` | `gateway:startup` | Run `BOOT.md` when gateway starts |

---

## Hook Configuration Shape

```json
{
  "hooks": {
    "internal": {
      "enabled": true,
      "entries": {
        "session-memory": { "enabled": true },
        "my-custom-hook": {
          "enabled": true,
          "env": { "MY_VAR": "value" }
        }
      },
      "load": {
        "extraDirs": ["/path/to/more/hooks"]
      }
    }
  }
}
```

Custom hooks can be placed at:
- `<workspace>/hooks/my-hook/` — per-agent, highest precedence
- `~/.openclaw/hooks/my-hook/` — shared across workspaces

---

## Key Finding

The `session-memory` hook fires on `/new` only. There is no `session:start` event in the
current version. The best alternative for near-real-time session-start ingestion is a
short-interval cron job (see `session-start-trigger-design.md`).
