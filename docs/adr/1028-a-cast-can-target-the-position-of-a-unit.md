# 1028. A cast can target the position of a unit

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules), ADR 0606 (after_trigger_steps)

## Context

Mojo Beam 501117: "While channeling, you can instantly cast Potion Toss, Splash Potion and Spirit in a Bottle at a
$573288s1% increased cost." Splash Potion 802710 is ground-targeted (Targets 64, TARGET_DEST_DEST). The harness cast
accepts an absolute `destination {x, y, z}`, which a generator cannot know, and no `metric_delta` step casts anything
after the trigger, so no entry casts a potion into a running channel (cycle 10 proposal "a cast destination at a unit's
position"; the Potion Toss and Splash Potion claims had no label).

## Decision

- Harness (`CoAGameplayTest.cpp` player cast path, `run.py`): `cast`, `use_item` and `cast_charm` accept
  `destination_unit` (a player or creature id) in place of `destination`; the cast sends that unit's current position
  as its ground target and records it.
- `metric_delta` option module `after_trigger_casts`: real casts by the caster in the treatment phase after the
  trigger, each after its `delay_ms`, with its cooldown reset and its `CasterAuraSpell` set, at a `target` and
  optionally at a `destination_unit`.
- Witch Doctor entries: `501117 potion_in_channel`, `potion_keeps_beam`, `splash_in_channel` and `splash_keeps_beam`:
  the potion cast 1700 ms into the Beam completes, and the Beam still channels 500 ms later; the uncast before phase
  is the control.

## Consequences

- New field and option only; no existing scenario names them. Generated scenarios of classes 19 (with and without
  `--stack`) and 23 are byte-identical; class 13 gains four scenarios.
- Catalog scenario `witch-doctor-harness-destination-unit.json`: a Splash Potion cast at the dummy's position
  completes and heals the doctor beside it.
- Seeded tests in `metric_delta_options/test_after_trigger_casts.py`.
