# Shared-Drive Multi-Agent Memory Design

Date: 2026-03-18  
Scope: applying Aethon's current markdown-based memory system (`memory/YYYY-MM-DD.md`, `learnings/LEARNINGS.md`, `MEMORY.md`, nightly consolidation/eval) to a shared network drive used by multiple concurrent Claude/OpenClaw instances across machines.

## Recommendation Up Front

Use a **hybrid architecture**:

1. **Many writers** may publish **immutable per-agent segment files** to the shared drive.
2. **Exactly one designated consolidator/indexer** publishes canonical shared files:
   - `memory/YYYY-MM-DD.md`
   - `learnings/LEARNINGS.md`
   - `MEMORY.md`
   - `agents/*/MEMORY.md`
   - search/index snapshots
3. Treat the shared drive as a **durable mailbox + artifact store**, **not** as a safe place for concurrent in-place edits.
4. Do **not** rely on `flock`/lockfiles as the primary safety mechanism across SMB/NFS-like storage.
5. Do **not** use a shared live SQLite/WAL/QMD mutable index on the network drive.

That is the default I would actually ship.

---

## Why This Design Fits Our Existing Memory Pattern

Current pattern:
- Agents write or save session notes into daily logs.
- A nightly consolidation pass promotes durable facts into `MEMORY.md` and `LEARNINGS.md`.
- Retrieval depends on markdown files plus QMD/search indexing.

That pattern already has a natural split:
- **runtime capture** = noisy, frequent, concurrent
- **promotion** = slower, curated, opinionated

On a shared drive, the mistake would be treating both as the same write path.

The safe design is:
- runtime capture becomes **append-only / immutable event publishing**
- promotion remains **single-writer materialization**

This preserves the current mental model while removing the corruption risks from multi-host concurrent markdown edits.

---

## Threat Model / Failure Modes

Assume the shared storage is SMB/NFS-like, mounted on multiple hosts, with imperfect lock semantics, caching, latency, and occasional disconnects.

### 1. Simultaneous writes to the same markdown file
If two agents both patch `MEMORY.md` or `memory/2026-03-18.md`:
- one update can clobber the other
- line edits can interleave or produce invalid markdown
- read-modify-write races cause lost updates even if each write individually succeeds

This is the most obvious failure mode and the one to eliminate completely.

### 2. Partial writes / torn files
An agent can crash or lose the network mid-write, leaving:
- truncated files
- zero-byte files
- partially copied temp files
- files visible before the full payload is durable

This matters especially for direct appends and in-place rewrites.

### 3. Stale client views / stale indexes
Network filesystems may expose:
- delayed metadata visibility
- client caching / oplock effects
- one host seeing a new file before another does
- indexers building from a partially updated view of source files

Result: the shared markdown may be correct, but search results lag or differ by host.

### 4. Duplicate promotions
If two consolidators process the same raw notes:
- the same preference can be promoted twice
- the same learning can be appended twice
- per-user `agents/*/MEMORY.md` files can diverge or bloat

Even without corruption, duplicate promotion quietly degrades memory quality.

### 5. Lock contention and false safety
`flock`/`lockf`/advisory lockfiles may:
- work differently across NFS vs SMB
- depend on kernel/server/mount options
- appear acquired locally but not protect remote clients consistently
- deadlock, wedge, or leave stale lockfiles after crashes

This is worse than no lock if it creates false confidence.

### 6. Split-brain leader election
If automatic failover uses only shared-drive lockfiles/leases, a network partition or stale cache can let two hosts both believe they are leader.

That gives you two simultaneous consolidators or index publishers.

### 7. Network filesystem semantics
Relevant practical caveats:
- Linux `flock()` semantics over NFS/SMB vary; over SMB they changed materially in newer kernels and can become mandatory-like depending on protocol/mount/server behavior.
- The `flock(2)` man page explicitly notes varying remote semantics for SMB and NFS.
- SQLite's own WAL docs explicitly say **WAL does not work over a network filesystem** because it requires shared memory on the same host.
- More broadly: anything depending on precise cross-host advisory locking or shared mutable local-db internals is fragile here.

### 8. Clock skew / ordering ambiguity
Different hosts can disagree on time by seconds or minutes.
If ordering is inferred only from wall-clock timestamps, a daily reconstruction can be unstable.

### 9. Reader/writer interference during indexing
If index data is mutated in place while others query it:
- queries can fail
- caches can corrupt
- one host can read half-updated index state

### 10. Human-operational failure
Even if the design is sound, agents may still accidentally:
- write directly to canonical files
- bypass the segment protocol
- run a second consolidator "just this once"

The design should make the safe path obvious and the unsafe path unnecessary.

---

## What the Research Implies

A few concrete takeaways from external references:

- SQLite WAL: official docs say WAL requires shared memory and **does not work over a network filesystem**. That rules out "shared live SQLite/WAL DB on the drive" as the default backend for multi-host concurrent memory state.
- `flock(2)`: Linux man page notes NFS and SMB behavior differs by version and setup; SMB behavior in particular can become non-advisory/mandatory-like and varies by server/mount options. That is a strong argument against depending on `flock` as the core cross-host coordination primitive.
- Lennart Poettering's long-standing "broken file locking" writeup is opinionated, but the important practical point holds: file locking across shared/network filesystems is messy, easy to misuse, and often impossible to verify confidently in heterogeneous environments.

So the boring conclusion is the right one: **design for correctness without needing distributed advisory locks to be perfect**.

---

## Strategy Comparison

## Strategy A — Direct shared markdown files with `flock` / lockfiles

### Shape
All agents read and write the canonical markdown files directly, using `flock`, `lockf`, or `.lock` files around edits.

### Pros
- Minimal conceptual change from the current setup
- Easy to prototype
- Keeps everything in markdown only

### Cons
- Fragile on SMB/NFS-like storage
- Still vulnerable to stale-lock and split-brain conditions
- Requires every writer to behave perfectly
- Hard to reason about correctness under host crash or network partition
- In-place markdown edits are still race-prone

### Verdict
**Not recommended** as the primary design.
Good enough only for a single host or a truly local filesystem.

---

## Strategy B — Append-only per-agent logs + periodic consolidation

### Shape
Each agent writes only to its own immutable raw log/segment files. A consolidator later materializes shared daily logs and promotes durable facts.

### Pros
- Excellent fit for the current daily-log + nightly-promotion workflow
- Avoids same-file concurrent writes
- Crash-safe if each publish is temp-file-then-rename
- Easy to make idempotent
- Raw provenance is preserved for auditing/debugging
- Allows eventual consistency without corruption

### Cons
- Canonical files are slightly delayed unless materialized frequently
- Requires a consolidator and some bookkeeping manifests
- Retrieval needs to target either materialized views or recent raw segments too

### Verdict
**Recommended core strategy.**
This should be the base of the shared-drive design.

---

## Strategy C — Single-writer leader + many readers

### Shape
One elected writer host owns all canonical files; all other agents send it work or write to an inbox it later processes.

### Pros
- Strong safety for canonical markdown and shared indexes
- Easy mental model
- Good fit for `MEMORY.md`, `LEARNINGS.md`, and indexing

### Cons
- Leader election is the hard part
- Automatic failover via shared-drive lockfiles risks split brain
- If the single writer is down, promotion/indexing pauses

### Verdict
**Recommended for publication/promotion/indexing, but only with pragmatic ownership.**
Prefer a **fixed designated writer host** over clever auto-election on the shared drive.

---

## Strategy D — Shared SQLite / small local DB mirrored to shared drive

### Shape
Use SQLite as the canonical multi-agent store on the network drive, then generate markdown from it.

### Pros
- Better structured dedupe/query model than raw markdown
- Easy to model promotions and manifests

### Cons
- Shared SQLite over SMB/NFS is exactly where people get into trouble
- WAL is explicitly unsuitable over network filesystems
- Even rollback-journal mode still leaves you with shared-db semantics on shaky storage
- Moves the problem, doesn't remove it

### Verdict
**Do not use as a shared live multi-host primary store on the drive.**
If SQLite is used at all, it should be **local per-host** or **local on the designated consolidator**, with exported artifacts published to the share.

---

## Strategy E — CRDT / fully distributed event-sourced memory

### Shape
Every memory item is an operation in a replicated log; state is merged via CRDT rules or a custom reducer.

### Pros
- Elegant distributed-systems answer
- Can tolerate multi-writer operation without locks
- Strong auditability

### Cons
- Big complexity increase
- Hard to map cleanly onto curated markdown memory semantics
- Promotion of durable facts is still subjective, not just commutative state merge
- Overkill for this use case

### Verdict
Interesting academically. **Not the pragmatic default**.
A light event-sourcing flavor is useful; full CRDT architecture is not.

---

## Recommended Architecture

Use a **hybrid of Strategy B + Strategy C**:
- **B for runtime ingestion**: immutable per-agent segment files
- **C for publication**: one designated consolidator/indexer publishes canonical artifacts

### Design principles
1. **No concurrent in-place writes to canonical files**
2. **Raw writes are immutable and uniquely owned by the publishing agent**
3. **Canonical markdown is generated, not collaboratively edited**
4. **Safety comes from write ownership + idempotency, not from locks alone**
5. **Search indexes are published as immutable snapshots, never mutated in place by many hosts**

---

## Runtime Protocol

## What each agent may write directly

Each running Claude/OpenClaw instance may write only to:
- its own raw segment files under the shared ingest area
- optional local scratch/state on its own machine

Each segment should contain a small batch of observations, for example:
- session save / handover notes
- candidate durable facts
- candidate learnings/rules
- source metadata (agent, host, session, timestamp)

### Direct writes allowed
- `incoming/segments/YYYY-MM-DD/<host>/<agent>/<session>/<timestamp>-<ulid>.md`
- `incoming/segments/YYYY-MM-DD/<host>/<agent>/<session>/<timestamp>-<ulid>.json` if structured metadata is preferred

### Direct writes forbidden
Agents must **not** directly write or patch:
- `MEMORY.md`
- `learnings/LEARNINGS.md`
- `memory/YYYY-MM-DD.md`
- `memory/consolidated/*`
- `memory/archive/*`
- `agents/*/MEMORY.md`
- `index/CURRENT`
- live shared QMD/index cache files

## What must be consolidated later
Only the designated consolidator may publish:
- canonical daily logs
- promoted long-term memory
- promoted learnings
- per-user memory files
- monthly rollups / archive moves
- index manifests and index snapshots

---

## Exact Shared-Drive File Layout

Assume the shared drive is mounted as the memory root.

```text
<shared-memory-root>/
  MEMORY.md                          # canonical, single-writer only
  learnings/
    LEARNINGS.md                     # canonical, single-writer only
  memory/
    2026-03-18.md                    # canonical materialized daily log
    consolidated/
      2026-03.md
    archive/
      2025-09.md
    metrics/
      dashboard.md
      2026-03-18.json
  agents/
    isabelle/
      MEMORY.md                      # canonical, single-writer only
    jaison/
      MEMORY.md                      # canonical, single-writer only

  incoming/
    segments/
      2026-03-18/
        macmini-main/
          main/
            agent_main_217976152/
              20260318T001504Z-01HQ8K....md
              20260318T003122Z-01HQ8M....md
        office-mini/
          external-gamedev/
            group_-5287514665/
              20260318T002045Z-01HQ8L....md

  state/
    processed-segments/
      2026-03-18.jsonl              # segment_id, hash, processed_at, generation
    promotions/
      memory-promotions.jsonl       # promotion_id, fact hash, source ids
      learnings-promotions.jsonl
    manifests/
      source-gen-000123.json        # exact source files used for a published generation
      source-gen-000124.json
    leases/
      consolidator.json             # advisory lease only, not primary correctness mechanism
      indexer.json

  index/
    snapshots/
      gen-000123/
        ... immutable published index snapshot ...
      gen-000124/
        ...
    CURRENT                         # tiny pointer file: gen-000124
```

### Notes on this layout
- The top-level canonical files mirror the current Aethon memory layout, so existing habits and prompts stay recognizable.
- `incoming/segments/` is the only shared multi-writer area.
- Every writer gets a unique path namespace by host + agent + session.
- `state/` is controlled by the consolidator/indexer only.
- `index/snapshots/` stores immutable generations; `CURRENT` flips only after a full snapshot is published.

---

## Segment Format

Keep it boring and inspectable.

A markdown segment is fine if it starts with a small metadata header.

Example:

```markdown
---
segment_id: 01HQ8KXYZ...
host_id: macmini-main
agent_id: main
session_id: agent:main:telegram:...
created_at: 2026-03-18T00:15:04Z
entry_count: 3
content_hash: sha256:...
---

## Notes
- Justin confirmed X
- Project Y is blocked on Z

## Candidate durable facts
- Justin prefers ...

## Candidate learnings
- Always ... when ...
```

If more structure is wanted later, move to JSON sidecars or JSON-only segments. But markdown segments are enough for this system.

The critical fields are:
- `segment_id`
- `host_id`
- `agent_id`
- `session_id`
- `created_at`
- `content_hash`

Those make dedupe and auditing straightforward.

---

## Conflict-Avoidance Rules and Lock Discipline

## Rule 1: one path, one writer
No path should have multiple live writers.
- raw segment paths are writer-owned
- canonical files are consolidator-owned
- index publication paths are indexer-owned

This matters more than any lock primitive.

## Rule 2: publish by temp file + atomic rename
For any shared-drive publish:
1. write full contents to a temp file in the same target directory
2. flush/sync if tooling allows
3. rename to final name only when complete
4. readers ignore temp files

That applies to:
- segment files
- canonical markdown rebuilds
- manifest files
- `index/CURRENT`

## Rule 3: immutable once published
Published segment files must never be edited in place.
If an agent needs to correct something, it publishes a new segment.

## Rule 4: no append-to-shared-file from many hosts
Even appending to one shared `.jsonl` file from many hosts is not safe enough here.
Use many immutable files, then materialize.

## Rule 5: advisory leases only, not correctness-critical locks
If a `consolidator.json` lease is used, it is for:
- avoiding accidental overlapping runs
- observability
- stale-owner detection

It must **not** be the only thing preventing corruption.
If two consolidators ever run, idempotent processing and single publication rules must still limit damage.

## Rule 6: fixed owner beats auto-election
Prefer:
- `memory-primary = macmini-main`
- `index-primary = macmini-main`

If that host is down, backlog accumulates safely in `incoming/segments/`.
That is acceptable.

Only introduce automatic failover if there is a proper external coordinator (e.g. Postgres, Redis, etcd, or similar) outside the shared filesystem. Do **not** build split-brain-prone leader election out of SMB/NFS lockfiles alone.

## Rule 7: idempotency everywhere
The consolidator should record:
- `segment_id`
- `content_hash`
- publication generation
- promotion ids / fact hashes

Reprocessing the same segment should be harmless.
Duplicated raw input should not create duplicated `MEMORY.md` or `LEARNINGS.md` lines.

---

## Recommended Handling for Shared Daily Logs

Do **not** let agents collaboratively edit `memory/YYYY-MM-DD.md`.

Instead:
- agents publish raw segments throughout the day
- consolidator rebuilds `memory/YYYY-MM-DD.md` from those segments on a cadence
- rebuild is deterministic: sort by `(created_at, segment_id)` and render

### Why this is better
- no lost updates from line-based patching
- canonical daily log can be regenerated from source truth
- easier debugging when a note looks wrong
- if a daily file gets corrupted, rebuild it from raw segments

### Practical cadence
- every 5-15 minutes: materialize today's daily log from new segments
- on session-save / handover heavy periods: can run more often if needed
- nightly: final rebuild before promotion

---

## Recommended Handling for LEARNINGS.md and MEMORY Promotion

`LEARNINGS.md` and `MEMORY.md` are not runtime collaboration surfaces. They are curated outputs.

### Promotion flow
1. consolidator reads new raw segments since the last promotion checkpoint
2. extracts candidate durable facts and learning rules
3. dedupes using normalized hash / similarity rules
4. updates canonical files by full-file rewrite to temp + rename
5. records promotion ledger entries with source segment ids

### Duplicate-promotion control
Maintain ledgers such as:
- `state/promotions/memory-promotions.jsonl`
- `state/promotions/learnings-promotions.jsonl`

Each promoted item should carry:
- `promotion_id`
- normalized fact/rule hash
- source segment ids
- target file + generation

That makes reruns safe and auditable.

### Contradictory facts
If a new candidate contradicts existing memory:
- prefer update-in-place by the consolidator during the canonical rewrite
- record the replacement in the promotion ledger
- optionally stage ambiguous conflicts in `state/review/` for human review instead of blindly merging

---

## QMD / Search Indexing in Multi-Instance Setups

## What not to do
Do **not** have multiple hosts mutating one shared live QMD/index directory on the network drive.

Reasons:
- shared mutable index state is corruption-prone
- caches and file visibility differ across clients
- local-db internals often assume stronger filesystem semantics than SMB/NFS gives
- SQLite WAL specifically is not viable over network filesystems

## Recommended pattern
Use **canonical markdown on the shared drive + local or immutable index snapshots**.

### Option 1 — Best default: local per-host indexes
Each host:
- reads canonical markdown from the shared drive
- keeps its own local QMD/index cache on local disk
- rebuilds or refreshes when `state/manifests/source-gen-XXXXX.json` or `index/CURRENT` changes

Pros:
- safest runtime behavior
- no shared mutable index corruption
- each host can keep serving queries if the shared drive is briefly slow

### Option 2 — Single-host build, immutable shared snapshots
A designated indexer host:
- builds the index locally from a canonical source generation
- publishes finished snapshot to `index/snapshots/gen-XXXXX/`
- atomically updates `index/CURRENT`

Readers:
- either query a local copy of that snapshot
- or remount/use the shared snapshot read-only if performance is acceptable

### Recommendation for this setup
For Claude/OpenClaw-style agents, I would use:
- **canonical markdown on shared drive**
- **local per-host QMD caches/indexes**
- **one designated index publisher** only if Justin wants consistent snapshot generation tracking

If QMD must be shared at all, share **source files and immutable published snapshots**, not live writable cache directories.

---

## Consolidation Cadence and Ownership

## Ownership
- `memory-primary`: one designated host, fixed by config
- `index-primary`: same host unless load requires separation

Avoid automatic failover at first.
A paused consolidator is annoying; a split-brain consolidator is worse.

## Cadence

### Runtime capture
- agents publish segments immediately on save/handover
- optional small periodic flush: every 5-10 minutes for long sessions

### Daily materialization
- every 5-15 minutes: rebuild today's `memory/YYYY-MM-DD.md`
- keep it cheap and deterministic

### Promotion
- nightly at 03:00 SGT: promote to `MEMORY.md`, `LEARNINGS.md`, `agents/*/MEMORY.md`
- optional midday mini-promotion if Justin wants fresher long-term memory, but nightly is enough initially

### Indexing
- after each promotion or daily materialization batch, publish a new source generation marker
- rebuild indexes on demand or on a 15-60 minute cadence depending on cost

---

## Failure Recovery Model

This architecture should fail by **delay**, not by corruption.

If an agent crashes:
- worst case: one segment publish is missing or temp-only
- canonical memory remains intact

If the consolidator crashes:
- raw backlog accumulates in `incoming/segments/`
- next run resumes from unprocessed segments

If the shared drive is briefly unavailable:
- hosts may queue segments locally and retry publish later
- canonical files are unchanged rather than half-written

If two consolidators accidentally run:
- idempotent segment tracking and promotion ledgers reduce duplicate effects
- fixed ownership and generation manifests make diagnosis obvious

---

## Specific Recommendation for Claude/OpenClaw + Markdown Memory Files

For this actual setup, I would implement the following policy:

### Agents
- read canonical shared markdown files freely
- never directly edit canonical shared markdown files
- emit raw markdown segments only
- include `segment_id`, host, agent, session, UTC timestamp in each segment

### Consolidator
- runs on one pinned host only
- materializes `memory/YYYY-MM-DD.md` from raw segments
- promotes durable facts nightly into `MEMORY.md`
- promotes durable rules nightly into `learnings/LEARNINGS.md`
- updates `agents/*/MEMORY.md` from the same source pool
- writes ledgers/manifests for idempotency and audit

### Indexing
- indexes canonical files only
- never indexes directly from still-arriving raw temp files
- uses local disk for active index work
- publishes immutable generation markers/snapshots if needed

This is very close to the current mental model, just with proper multi-writer isolation.

---

## Pragmatic Implementation Plan

## Phase 1 — Safety rails first
- Define and document canonical-vs-raw ownership rules
- Create `incoming/segments/`, `state/`, and `index/` directories on the shared drive
- Update prompts/workflow so agents write segments, not direct shared markdown edits
- Add unique host/agent/session identifiers

### Exit criteria
No runtime agent writes directly to canonical shared files anymore.

## Phase 2 — Deterministic daily materialization
- Build a consolidator step that reads raw segments and rewrites `memory/YYYY-MM-DD.md`
- Add `processed-segments` manifest and deterministic ordering
- Verify rebuild-from-source works for a test day

### Exit criteria
Today's daily log is generated from segments, not manually appended by many agents.

## Phase 3 — Promotion ledgers
- Add `memory-promotions.jsonl` and `learnings-promotions.jsonl`
- Convert nightly promotion to idempotent full-file publish
- Add duplicate suppression by normalized hash

### Exit criteria
Re-running promotion does not duplicate facts or rules.

## Phase 4 — Index publishing discipline
- Stop sharing live writable index/cache dirs
- Move active QMD/index work to local disk per host
- Optionally publish immutable snapshots + `CURRENT`

### Exit criteria
No multi-host live mutation of one shared index directory.

## Phase 5 — Operational hardening
- Add stale-segment alerts, lease visibility, manifest inspection, generation counters
- Add backup/manual failover runbook for `memory-primary`
- Optionally add local spool-and-retry when the shared drive is offline

### Exit criteria
Failures degrade to backlog, not corruption.

---

## Recommended Default

If I had to pick one design and stop thinking about it:

- **Agents write only immutable per-agent segment files to the shared drive.**
- **One fixed host publishes all canonical markdown and index generations.**
- **No multi-host in-place edits to `MEMORY.md`, `LEARNINGS.md`, daily logs, or shared index state.**
- **Use temp-file + rename publication, idempotent manifests, and promotion ledgers.**
- **Keep QMD/indexes local per host, or publish immutable snapshots only.**
- **Do not rely on SMB/NFS advisory locking as your main safety mechanism.**

That is the boring, robust design for multiple concurrent Claude/OpenClaw instances sharing markdown memory over a network drive.

---

## References

- SQLite WAL documentation: https://www.sqlite.org/wal.html
- Linux `flock(2)` manual page: https://man7.org/linux/man-pages/man2/flock.2.html
- Lennart Poettering, "On the Brokenness of File Locking": http://0pointer.de/blog/projects/locking.html
