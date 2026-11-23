# 0650. A minion trigger sets its held caster health before the attack

- Status: accepted
- Date: 2026-11-14

## Context

A minion trigger entry with `caster_health_pct` held the caster's health by a `set_health` step before every
`minion_aura_refresh_ms` window, the first one right after the `attack` step. The harness runner takes one step per
world tick (`CoAGameplayTest.cpp` `Progress()` runs one `RunStep` and returns), and a minion with a ready swing timer
lands its first hit right after the attack (diagnostic 20261114-025240: three Ghoul hits in the first 4000 ms window of
2000 ms swings), so that hit can land in the tick before the first `set_health`, at the caster's natural health.
Vampiric Aura 300241 heals only while the owner is below 50% health (`AscensionNecromancerEvents.cpp:97`,
`HealthBelowPct(50)`).

This decision was first taken as the cause of the Vampiric Aura shortfall of one heal per part (cycle 13). The cycle 14
pair, run with it, kept the shortfall; the cause is the aura reaching the minion one second after the learn (Necromancer
ADR 0080, `aura_settle_ms`). The ordering stays as a guard: once the aura is in place, the first hit must also land at
the held health.

## Options

1. Set the held health before the `attack` step as well, so every counted hit lands while the caster is held.
2. Leave the first hit out of the trials by a reading.
3. Widen the trigger count tolerance by one per part.

## Decision

Option 1. `minion_attempt_steps` places the `caster_health_pct` fixture before `attack`; the per-window fixture is
unchanged. Option 2 adds a reading for an artefact of the step order, and option 3 widens a tolerance the mentor ruled
out.

A minion trigger may also wait `aura_settle_ms` after its learn (with `aura_settle_source`) when the passive reaches the
minion only after a delay the DBC states; the wait is stated in the rule.

## Consequences

- The scenarios of minion trigger entries with `caster_health_pct` gain one `set_health` step before the attack
  (Necromancer: the three Vampiric Aura 300241 entries); the Necromancer digests are refreshed. Templar's generated
  scenarios do not change.
- Seeded tests: test_triggers.py `MinionHeldHealthTests`.
