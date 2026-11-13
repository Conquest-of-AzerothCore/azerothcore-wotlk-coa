# 0402. Humanoid targets for metric delta and fixed count

- Status: accepted
- Date: 2026-11-13

## Context

Mass Grave 803741 affects Humanoids only (TargetCreatureType 64), while every metric delta and fixed count scenario
places the Mechanical Harvest Golem 36 as its dummy. B2 side b added `target_entry` to `metric_delta` for Ghoulify
800706 (commit 30499bac54, ADR 0381), together with enemy casts and target health on top of B2 tools this branch does
not hold. Mass Grave's "up to $i nearby enemies" also needs several Humanoids around the caster.

## Considered options

1. Cherry-pick 30499bac54 and add `dummy_entry` to `fixed_count`. Chosen (controller, 2026-11-13): 30499bac54 and
   the B2 side b tool commits it builds on (89d45acae1, ea399d98cd, 9e40786ee1, 4e274eaa55) are cherry-picked, so
   `metric_delta` has one copy of `target_entry`.
2. Write `target_entry` again in this branch. Rejected: two copies of the same field for the integrator.

## Decision

- `metric_delta`'s `target_entry` is ADR 0381's (cherry-picked); Mass Grave's entries use it.
- `fixed_count` takes `dummy_entry`: the creature entry of every dummy it places, the far one included.

## Consequences

- Entries without the fields generate as before: Templar `generate --class 19` and `--stack` are byte-identical.
- Mass Grave reads its targets, durations and creature type on Kobold Vermin 6 (creature type 7 Humanoid).
- The cherry-picked B2 side b tests that read that branch's class-file entries stay on that branch.
