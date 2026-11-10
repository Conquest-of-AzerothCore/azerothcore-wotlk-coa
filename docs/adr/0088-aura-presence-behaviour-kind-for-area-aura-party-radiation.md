# 0088. Aura-presence behaviour kind for area-aura party radiation

## Context

Harmonic Disposition's tooltip ends "...and granting the ability to walk on water." Its own DBC record
carries a `SPELL_EFFECT_APPLY_AREA_AURA_RAID` effect (`EffectApplyAuraName[1]` 104, `SPELL_AURA_WATER_WALK`)
targeting the caster (`Range.dbc` id 1, Self Only) with a 40 yd radius (`SpellRadius.dbc` id 23): the server's
area-aura system re-applies the water-walk aura from the caster onto nearby party/raid members, so the
tooltip's claim is only proven by reading the aura on a grouped ally, not on the caster. No existing
behaviour kind measured a metric on a non-caster target before/after a self-targeted cast; `dispel_removal`
is the closest (it already measures `aura` on a grouped `ally` target before/after a cast) but is hardcoded
to the `aura` metric and to a removal (`before_expected: 1.0`, `expected: 0.0`), the opposite polarity of a
presence check.

## Decision

- A new `aura_presence` behaviour kind (`AuraPresenceSpec`/`aura_presence_scenario`/`aura_presence_spec` in
  `behaviours.py`) casts the spell under test on the caster, then measures an arbitrary metric (`water_walk`
  for this clause, but any metric name with its own `fields`) on `spec.target` before and after, grouping the
  caster and the target first when the target is not the caster (the `group` action, the same mechanism
  `triggers.py`'s existing ally-target trigger scenarios already use to put a second player fixture in party
  range).
- The expectation reuses the existing `BEHAVIOUR_METRIC_DELTA` check and its `behaviour_metric_delta_verdict`
  judge unchanged, with `before_expected: 0.0` / `expected: 1.0`: no new judge code, matching this round's
  `dispel_removal` precedent of reusing the metric-delta judge for a non-numeric presence/absence read.

## Consequences

- Harmonic Disposition 560653 gains a `water_walk` presence expectation on a grouped ally, proving the
  area-aura radiation actually grants the aura to a nearby party member, not just that the caster's own copy
  of the aura exists.
- Any other class's self-targeted area aura (party/raid) gets the same scenario for free by adding an
  `aura_presence` entry naming its own water-walk/stat/aura metric; the tool code makes no Templar-specific
  assumption beyond the class file's own spell id and metric name.
- `KINDS` in `behaviours.py` gains `'aura_presence'`; `behaviour_scenario`'s dispatch gains the matching
  branch.
