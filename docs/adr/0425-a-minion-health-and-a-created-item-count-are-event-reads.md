# 0425. A minion's health and a created item count are event reads

- Status: accepted
- Date: 2026-11-13

## Context

Bone Tithe 802121 takes 40% of each minion's current health, and Create Frozen Reliquary 803777 creates 5 items. The
harness reads both already (`owned_creature_health`, `item_count`), but `coverage.METRIC_EVIDENCE` had no class for
them, so any verdict on them stopped coverage with an EvidenceError.

## Decision

Both are event reads, as `health` (ADR 0381) is: the value an action leaves on a unit or in the bags, read after the
action against a control without it.

## Consequences

`OwnedHealthAndItemCountTest` (test_coverage.py) holds the two rows.
