# Shared-Drive Manifests and Ledgers

Use manifests and ledgers to make shared-drive consolidation idempotent and auditable.

## Required State Files
- `state/processed-segments/YYYY-MM-DD.jsonl`
- `state/promotions/memory-promotions.jsonl`
- `state/promotions/learnings-promotions.jsonl`
- `state/manifests/source-gen-XXXXXX.json`
- `index/CURRENT`

## Processed Segment Ledger
Record for each processed segment:
- `segment_id`
- `content_hash`
- `processed_at`
- `generation`

## Promotion Ledger
Record for each promoted fact/rule:
- `promotion_id`
- normalized fact/rule hash
- source segment ids
- target file
- generation

## Generation Manifest
Each canonical publication generation should describe:
- exact source segment ids included
- timestamp
- consolidator host id
- output files produced
- index generation if any

These files are consolidator-owned only.
