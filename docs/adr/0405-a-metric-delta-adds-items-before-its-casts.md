# 0405. A metric delta adds items before its casts

- Status: accepted
- Date: 2026-11-13

## Context

Create Bone Reliquary 803771 "Create $s1 Bone Reliquaries" consumes one reagent, 37201, and creates five of item 11521.
A `metric_delta` had no step that puts a reagent in the caster's bags, and the harness's `item_count` read had no
evidence class in `coverage.METRIC_EVIDENCE`.

## Decision

- `metric_delta` takes `items` (`[item, count]` pairs): an `add_item` of each right before every cast of the trigger
  spell, in both phases.
  On the merged branch the field is dropped: `reagent_steps` (ADR 0361) already adds the cast's `Reagent[i]` before
  every trigger and setup cast, and both together added 37201 twice. One implementation stays.
- `item_count` is a state read (the caster's bags), promised by a clause that names a creation (`creat\w*`).

- A `metric_delta` whose waits pass `METRIC_DELTA_UNTIMED_WAIT_MS` (80000 ms) is timed (its waits plus the 60 s
  margin) instead of keeping the 90 s default timeout: Permafrost's 50 Command: Undead casts at the global cooldown
  timed out at the default. On the merged branch this threshold replaces ADR 0361's 90000 ms in the same rule, which
  keeps its cap at the accelerated scenario limit.

- `metric_delta` takes `caster_health` (`[value, maximum]`): the caster's health is set to it at the start of each
  phase, before any cast, for a heal of the missing health (Bone Reliquary 803767).

## Consequences

- Entries without `items` generate as before: Templar `generate --class 19` and `--stack` are byte-identical.
- Create Bone Reliquary reads 0 items without a cast and 5 after one.
- Mutants (B3ToolMutantTests): four Bone Reliquaries alert (five pass); the pre-fix double heal 5000 -> 9500 and
  2000 -> 7400 alerts (6500 passes); a Permafrost expired before its read (0 charges) alerts.
