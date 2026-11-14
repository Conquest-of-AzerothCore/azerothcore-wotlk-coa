# 0493. A metric_delta corpse is killed by a real cast

- Status: accepted
- Date: 2026-11-13

## Context

Corpse Explosion 533239 ("Explode all nearby corpses ...", "Does not affect mechanical or elemental corpses.") and
Corpse Wagon 503738 ("increases the damage of Corpse Explosion by $s2%") need a corpse near the caster:
`CorpseExplosion()` (AscensionNecromancerAbilities.cpp:18-38) explodes dead creatures in the Corpse state within
15 yd of the caster, with their native display, not Mechanical or Elemental, on the attackable units within 10 yd of
each corpse. No scenario placed a corpse (tool gap "corpse fixture", 3 claims). Scenario creatures already take an
entry, a level, a health and a distance, and a setup cast can name a scenario unit, so no harness change is needed.

## Decision

- `metric_delta` takes `corpse`: `{"entry", "health", "distance"}` adds a stationary creature `corpse`.
- A setup cast may target `corpse` only when the entry declares one and only with `setup_only_after`: the creature is
  killed by a real cast in the treatment phase, and the control phase has no corpse. A declared corpse that no setup
  cast kills is refused.

## Consequences

- Corpse Explosion entries read 533240 damage on the dummy: 528 and 1078 at spell power 0 and 1000 for a Humanoid
  corpse, 0 for a Mechanical and an Elemental corpse; Corpse Wagon reads 678 (528 x 1.03 x 1.25 with integer
  truncation between the factors).
- Entries without `corpse` are unchanged; Templar `generate --class 19` and `--stack` are byte-identical.
- Tests: `CorpseFixtureTests` (test_behaviours.py).
