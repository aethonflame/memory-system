# Shared-Drive Failover Runbook

Default posture: use a **fixed designated consolidator host**.
Do not implement automatic leader election using only shared-drive lockfiles.

## Normal Operation
- `memory-primary` owns canonical publication
- `index-primary` owns snapshot publication (can be the same host)

## If the primary host is down
1. Leave runtime agents writing raw segments only
2. Let backlog accumulate safely in `incoming/segments/`
3. Manually designate a replacement host
4. Confirm the old host is truly down / disabled
5. Run consolidation from the replacement host
6. Record the ownership change in an operational note

## Why manual failover
Backlog is tolerable. Split-brain is not.
Human-confirmed failover is safer than clever lock-based election on SMB/NFS-like storage.
