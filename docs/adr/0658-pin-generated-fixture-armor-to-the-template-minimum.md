# 0658. Pin generated fixture armor to the template minimum

- Status: accepted
- Date: 2026-11-14

## Context

A creature fixture is summoned through `Creature::UpdateEntry`, which rolls `urand(minlevel, maxlevel)` and writes
the armor of the rolled level (`creature_classlevelstats` basearmor times the template's ArmorModifier) before the
harness sets the fixture's `level`. `Unit::SetLevel` does not recompute armor. The conformance dummy and striker,
Harvest Golem 36 (levels 11 to 12), therefore read 528 or 562 armor at level 60 from one run to the next, while
`mitigation.REFERENCE_TARGET` assumes 528. The other generated fixtures with a level range are Kobold Vermin 6
(1 to 2), Rusty Harvest Golem 480 (9 to 10) and Timberling 2022 (5 to 6); about 75 hand-written harness scenarios use
such templates too.

## Options

- Pin every fixture in the harness to its template's lowest-level armor: changes the armor of every hand-written
  harness scenario on a template with a level range, none of which asked for it.
- Recompute armor at the fixture's level (3750 at 60 for entry 36): needs `REFERENCE_TARGET.armor` 3750, changes the
  generated Templar hit scenarios and roughly two thirds of the physical damage on the dummy. An owner decision; not
  taken.
- An opt-in fixture field, set by the conformance generator.

## Decision

A creature fixture accepts `min_level_armor` (boolean, default false). When it is true, the harness sets the
fixture's `UNIT_MOD_ARMOR` base value, right after `SetLevel`, to its template's armor at `min(minlevel, maxlevel)`,
read at run time from the template and `creature_classlevelstats`; no value is written in code or data. A template
with minlevel equal to maxlevel keeps its native armor.

The conformance generator sets it by one rule: every creature fixture of every scenario it writes
(`pinned_fixture_armor` in `ManifestWriter.add`). No list of entries, so no guard for a missing field is needed.
Hand-written harness scenarios do not set it and are unchanged.

## Consequences

- Entry 36 reads 528 armor in every run, the value `REFERENCE_TARGET` already assumes.
- Generated scenarios gain the field on each creature and nothing else: `generate --class 19` (1942 of 2460 files,
  2083 creatures), `--class 19 --stack` (40 of 40, 40 creatures) and `--class 23` (3099 of 3731, 3378 creatures); the
  manifests differ only by those files' sha256. The committed digests of both finished classes (`snapshots/templar.json`,
  `snapshots/necromancer.json`) are refreshed for that reason only.
- Melee damage, attack power, mana and the other level-derived stats of a ranged fixture still follow the rolled level;
  base health comes from the fixture's `health` field. A claim that would read those needs its own pin.
- Regression: `gameplay-fixture-min-level-armor` (eleven pinned entry-36 fixtures read 528; a pinned Zulian Cub 11360,
  60 to 60, keeps 4125). Validation: `test_runner.py` (`min_level_armor` must be boolean); generator rule:
  `test_snapshots.py` (`FixtureArmorPinTest`).
