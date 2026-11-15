# 0079. `party_stat_ratio` behaviour check for raid-wide and radius-gated party buffs

- Status: accepted
- Date: 2026-11-10

## Context

The multi-target-aoe workstream's remaining clauses include several Templar passives whose tooltip claims a
bonus to "all party and raid members" (560550 Call of the Monastery, attack power; 300929 Serendipity, damage
dealt) or to allies "within $a1 yds" (300515 Fortified Body, healing received). Every existing self-measured
check for these spells (the generic `passives.py` `passive_delta` engine and the ad hoc `metric_delta` entries)
reads the stat on the caster alone. The caster is itself a party member, so a self-read is consistent with the
tooltip but does not distinguish "applies to the caster because the caster is in the party" from "applies to
the caster only"; it cannot touch the radius-gated clause (300515) at all, since the caster's own distance from
itself is always zero.

`coa-dbc-viewer` reads (this session) confirm all three spells apply via `Effect[0] = 65`
(`SPELL_EFFECT_APPLY_AREA_AURA_RAID`), a stock, no-CoA-code aura application mechanism: 560550 and 300929 use
`EffectRadiusIndex[0] = 287` (`SpellRadius.dbc` 100.0 yd, no distance token in either tooltip), 300515 uses
`EffectRadiusIndex[0] = 23` (`SpellRadius.dbc` 40.0 yd, matching its own `$a1` token). Each spell's `$s1` base
points plus its `DieSides = 1` roll match the tooltip's own percentage exactly (560550: 4+1=5%, 300929: 2+1=3%,
300515: 5+1=6%), so the only unproven part of each clause is breadth: does a different, non-caster party member
actually receive the bonus, and, for 300515, does it stop once that member leaves the 40 yd radius.

No existing scenario shape adds a second, grouped, non-caster player fixture at a controlled distance and reads
a stat on it before and after the caster learns a passive. The `trigger_entries.md`/`proc-rates.md` `target:
"ally"` mechanism (procs.py/triggers.py) already proves a second player fixture plus `group` is a supported,
schema-valid combination, but only for a cast landing on the ally, not for a passive read on the ally's own
stats.

## Considered options

1. Extend the generic `passives.py` `passive_delta` engine to optionally read a second, grouped ally instead of
   the caster. Rejected for this item: that engine scans every passive's generic engine-effect family across
   every class and spell automatically; adding an ally-read mode to it is a larger, class-agnostic change than
   three clauses justify, and risks changing behaviour for spells this item was not asked to touch.
2. Add a manual, per-clause `behaviour_*` kind, matching the pattern `fixed_count` already established in this
   same workstream (round 10 step 1) for a check shape the generic engines do not cover. Chosen.
3. Reuse `behaviour_duration_ratio`'s before/after ratio judging directly. Rejected: that verdict's explanation
   text and `model` fields are written specifically for an `aura_duration_ms` read on a vehicle-cast target
   (`vehicle_spell`, `target_name`); repurposing it for an arbitrary stat metric on an ally would either misname
   those fields or require a parallel set of fields with the same meaning under different names, which is no
   simpler than a dedicated verdict function.

## Decision

- `behaviours.py` gains `party_stat_ratio`/`BEHAVIOUR_PARTY_STAT_RATIO`: `PartyStatRatioSpec(spell, name, quote,
  expected, metric, metric_fields=(), radius=None, radius_reason='', near_distance=3.0, far_margin=15.0,
  needs_dummy_target=False, settle_ms=2000)`. `radius=None` builds one grouped ally (`party_ally_id(0)`,
  `'ally'`) and reads `metric` on it before and after `spell` is learned on the caster, expecting the ratio
  `after/before` to equal `expected`. `radius` not `None` additionally builds a second grouped ally
  (`party_ally_id(1)`, `'ally_far'`) positioned at `radius + far_margin` yd (via `relocate_steps`, chunked to the
  schema's 20 yd-per-step `relocate` limit) and expects its own ratio to stay at 1.0, isolating the radius gate
  the near-ally-only reading could not.
- `compare.py` gains `behaviour_party_stat_ratio_verdict`: `ok` when the near ratio matches `expected` within
  `PARTY_STAT_RATIO_TOLERANCE` (1e-4, the same order as `METRIC_DELTA_FLOAT_TOLERANCE`'s IEEE-754 allowance,
  since every value here is a deterministic formula read, never a combat roll) and, when present, the far
  ratio stays within the same tolerance of 1.0; `unmeasured` when a baseline reads non-positive (no basis for a
  ratio); `alert` on a missing measurement or either ratio failing its check.
- Wired for three Templar clauses whose only unproven part was breadth, not magnitude: 560550 (`attack_power`,
  no fields, no radius), 300929 (`spell_damage_done`, reusing the SAME reference spell 572741 the existing
  caster-side check already cites, `needs_dummy_target: true` since that metric requires a `target` unit),
  300515 (`spell_healing_taken`, reference spell 803792 reused from the existing self-measured note,
  `radius: 40.0`).
- No change to the generic `passives.py` engine, to any other behaviour kind's judging, or to any server code:
  all three clauses read `ok` as implemented, confirmed by two separate gameplay runs.

## Consequences

- A future party/raid-wide stat clause measurable with an existing `CoAGameplayTest.cpp` metric (any of
  `attack_power`, `spell_power`, `stat`, `spell_damage_done`, `spell_healing_taken`, `weapon_damage_min`, …) can
  reuse this kind directly from the class file, with no new Python or C++.
- A clause needing a metric this tool does not yet expose on an arbitrary unit (haste: 560096/567572's
  `SPELL_AURA_MOD_MELEE_RANGED_HASTE` has no matching `CoAGameplayTest.cpp` metric) or needing an actual heal
  cast rather than a formula read (805417's healing-received-%, which only exists once a heal lands) still needs
  its own follow-up, left to a later step of this workstream.
- `relocate_steps` (chunking any distance into ≤20 yd `relocate` actions) is now available to any future
  scenario builder needing to place a fixture farther than one `relocate` step allows; it is class-agnostic and
  carries no Templar-specific assumption.
