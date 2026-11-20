# 0687. Four behaviour kinds place the dummy by the ranged-path rule

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0680

## Context

ADR 0680 places the value and hit scenarios' dummy at `values.cast_distance` of the scenario's rank (the midpoint of a
`SPELL_RANGE_RANGED` range, the 3 yd melee distance otherwise) and leaves the other builders at `DUMMY_DISTANCE` until a
ranged entry needs them; `metric_delta` already has its own `dummy_distance`. The Witch Hunter cycle 6 authors were
blocked on ranged shots in `hit_ratio`, `script_hit`, `cost_gate` and `cast_applies_aura`: Darkslayer 804179 (range
114, 0-35 yd) landed 0 of 200 casts at the 3 yd dummy (single diagnostic run 20261115-113647) and every cast at 17.5
yd (diagnostic run 20261115-113828), so the damage claims of 503681 and 520670 were recorded as tool gaps. Mentor D-66
(approved under O-12): `dummy_distance` for those four kinds, defaulting to the midpoint of the spell's range for a
ranged ability; entries without it and finished classes unchanged; a test and a mutant.

## Options

- An explicit `dummy_distance` only: every ranged entry repeats a value the range data already gives (O-11: the
  distance comes from the spell's own range data).
- The ranged-path default only: no way to place the dummy where a claim needs another distance.
- The ADR 0680 rule as the default, with `dummy_distance` as an override.

## Decision

- `behaviours.dummy_placement(records, spell, stated, cast_spell)`: a stated `dummy_distance` must lie in (0, 100]
  yd (`METRIC_DELTA_MAX_DUMMY_DISTANCE`, the `metric_delta` bound); without it the distance is
  `values.cast_distance` of the spell cast at the dummy, or `DUMMY_DISTANCE` when no spell is cast at it.
- The spell cast at the dummy: `hit_ratio` its `cast_spell`, else its `observe_spell`, when it targets the dummy and
  does not swing; `script_hit` the first of its `casts` aimed at the dummy; `cost_gate` its `gated_spell` when it
  targets the dummy; `cast_applies_aura` its `cast_spell` (else the entry spell) when its cast target is the dummy,
  through `cast_applies_aura_distance`, which its expiry pair (`expiry.cast_applies_aura_expiry`) uses as well.
- A placement other than 3 yd is stated in the contract ("The dummy stands N yd from the caster."; for `hit_ratio`
  "; the dummy stands N yd from the caster"); a 3 yd placement leaves the contract and the fixture as they were.
- No missile wait is added in these kinds (ADR 0680 adds one in the value scenario only): an entry whose read follows
  a missile keeps its own wait.

## Consequences

- Templar (19, `all` and `--stack`) and Necromancer (23) generate byte-identical scenarios and manifests (digests
  compared with `snapshots/templar.json` and `snapshots/necromancer.json`: 2,302, 41 and 3,732 files, 0 differ).
- Witch Hunter: every current entry of the four kinds casts a non-ranged spell at the dummy, so its 852 scenarios and
  its manifest are unchanged. The default covers the spells the cycle 6 authors were blocked on (range 114, 17.5 yd):
  Darkslayer 804179, Heartseeking Bolt 807284, Quickdraw 806851 and 804193, Shadowblast 804191 and 680269, so their
  entries need no `dummy_distance`; they are still to be authored (503681 and 520670 damage, Silver Bullets, Sixfold
  Shot, Quickdraw, Darkrider's Shadowblast part, Darkhunter 503669).
- Tests in `test_behaviours.py` (`RangedDummyPlacementTests`): a ranged `hit_ratio` (Darkslayer 804179) places the
  dummy at 17.5 yd and states it, and a stated 20 yd overrides it; each of `cast_applies_aura`, `script_hit` and
  `cost_gate` keeps 3 yd and its contract for a melee cast and takes a stated distance; the `cast_applies_aura` expiry
  pair shares the stated distance; 0 and 150 yd are refused. Mutant: with `cast_distance` patched to the melee
  distance, the Darkslayer dummy stays at 3 yd and no placement is stated.
