# 0431. A metric delta trigger by item use

- Status: accepted
- Date: 2026-11-13

## Context

- Create Frozen Reliquary 803777: "Create $s1 Frozen Reliquary that restores $803773s1% of your missing mana." The
  restore happens when the created item 555555 is used (its spell 803773). `metric_delta` triggered only by a cast,
  so the restore was data, route pending (B4 side b).
- The harness has `use_item` (actor, item, spell): the normal item-use handler.

## Decision

- `metric_delta` takes `trigger_item`: the trigger step is `use_item` of that item with `trigger_spell` as its spell,
  in place of a cast. It needs `setup_only_after` (the setup cast creates the item), and the control phase then
  makes no use (a use with no item fails the scenario). It is refused unless the target is the caster, with no
  attack phases, `cast_in_before` false and no `trigger_only_after`.
- An entry without it is unchanged: `generate --class 19` and `--stack` are byte-identical (2460 and 40 scenarios).

## Consequences

- `MetricDeltaTriggerItemTests` (test_behaviours.py) checks the use after the creating setup cast and that no cast of
  803773 is made, and the refusal of a dummy target. Casting the trigger in place of the use is the mutant that the
  first test catches.
- The Reliquary restore entry reads the mana after a create (823 spent) and one use, against the spent control.
