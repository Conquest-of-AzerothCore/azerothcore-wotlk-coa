# 0650. A minion trigger sets its held caster health before the attack

- Status: accepted
- Date: 2026-11-14

## Context

A minion trigger entry with `caster_health_pct` held the caster's health by a `set_health` step before every
`minion_aura_refresh_ms` window, the first one right after the `attack` step. The harness runner takes one step per
world tick (`CoAGameplayTest.cpp` `Progress()` runs one `RunStep` and returns), so a minion with a ready swing timer
can land its first hit in the tick between `attack` and the first `set_health`, at the caster's natural health.
Vampiric Aura 300241 heals only while the owner is below 50% health (`AscensionNecromancerEvents.cpp:97`,
`HealthBelowPct(50)`). In the Necromancer cycle 13 pair its `trigger_count` read exactly one event short in each of the
nine parts that start from full health (parts 2-10, both runs; 2466 / 2475 and 2464 / 2473), and none short in part 1,
whose baseline phase leaves the caster at 45% when the passive's attack starts. The magnitude entry of the same
aura read one heal fewer than hits in each of its ten parts, all without a baseline.

## Options

1. Set the held health before the `attack` step as well, so every counted hit lands while the caster is held.
2. Leave the first hit out of the trials by a reading.
3. Widen the trigger count tolerance by one per part.

## Decision

Option 1. `minion_attempt_steps` places the `caster_health_pct` fixture before `attack`; the per-window fixture is
unchanged. Option 2 adds a reading for an artefact of the step order, and option 3 widens a tolerance the mentor ruled
out.

## Consequences

- The scenarios of minion trigger entries with `caster_health_pct` gain one `set_health` step before the attack
  (Necromancer: the three Vampiric Aura 300241 entries); the Necromancer digests are refreshed. Templar's generated
  scenarios do not change.
- Seeded test: test_triggers.py `MinionHeldHealthTests`.
