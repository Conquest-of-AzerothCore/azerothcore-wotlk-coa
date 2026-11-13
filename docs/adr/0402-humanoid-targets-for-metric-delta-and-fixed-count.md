# 0402. Humanoid targets for metric delta and fixed count

- Status: accepted
- Date: 2026-11-13

## Context

Mass Grave 803741 affects Humanoids only (TargetCreatureType 64), while every metric delta and fixed count scenario
places the Mechanical Harvest Golem 36 as its dummy. B2 side b added `target_entry` to `metric_delta` for Ghoulify
800706 (commit 30499bac54, ADR 0381), together with enemy casts and target health on top of B2 tools this branch does
not hold. Mass Grave's "up to $i nearby enemies" also needs several Humanoids around the caster.

## Considered options

1. Cherry-pick 30499bac54. Rejected: it depends on three earlier B2 side b tool commits and a harness change.
2. Write `target_entry` as 30499bac54 writes it, and add `dummy_entry` to `fixed_count`. Chosen.

## Decision

- `metric_delta` takes `target_entry`: the creature entry of its dummy, with the same field, check and error as ADR
  0381, so the integration of both branches meets the same lines.
- `fixed_count` takes `dummy_entry`: the creature entry of every dummy it places, the far one included.

## Consequences

- Entries without the fields generate as before: Templar `generate --class 19` and `--stack` are byte-identical.
- Mass Grave reads its targets, durations and creature type on Kobold Vermin 6 (creature type 7 Humanoid).
- The integrator keeps one copy of the `target_entry` lines when B2 side b and this branch meet.
