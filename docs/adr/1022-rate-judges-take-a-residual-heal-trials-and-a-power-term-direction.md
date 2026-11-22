# 1022. Rate judges take a residual, heal trials and fixture resets; a power term is judged by its direction

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Supplements [ADR 0603](0603-a-cooldown-reset-is-counted-from-its-clear-cooldown-packet.md),
  [ADR 0720](0720-a-cooldown-reset-rate-can-pool-identical-cases.md),
  [ADR 0781](0781-a-proc-rate-can-be-sized-for-a-per-pair-residual-target.md)
  and [ADR 1017](1017-a-cooldown-reset-rate-can-be-counted-from-auto-attack-hits.md)

## Context

Four Sun Cleric clauses had no judge (tool design group 3, mentor D-103, D-105, D-106):

- Cultivate Divinity 704920: "Effectively healing with Radiant Cascade has a $h% chance ..." (ProcChance 20) and
  "Effectively healing with Illumination has a $707520h% chance ..." (ProcChance 40). The handler rolls on
  `healing && direct` with `healing = GetEffectiveHeal()` (`AscensionSunClericEvents.cpp:51`, `:135`, `:336-338`): an
  overheal-only event never rolls, so completed casts are not the trials.
- Piety 300367: "Horusath Blast or Rapture now have a $h% chance to not incur a cooldown on cast." The roll is in
  `OnSpellCast` on a non-triggered cast (`AscensionSunClericAbilities.cpp:218`, `:253-254`) and calls
  `RemoveSpellCooldown(..., true)`, one `SMSG_CLEAR_COOLDOWN`. Both triggers cost a percentage of base mana and have a
  cooldown (25 s, 20 s), which `cooldown_reset_rate` refused; the harness `reset_cooldown` fixture that lifts the
  cooldown sends the same packet itself (`CoAGameplayTest.cpp:8865-8870`, `Player.cpp:3952-3958`), and the harness
  counts it (`ObserveExtensionPacket`, `CoAGameplayTest.cpp:1457-1466`, through the socketless packet observer).
- Odyn's Vanguard 806699: the `swing_reset_rate` kind (ADR 1017) had no residual option.
- Sun's Gift 680656: "Your Horusath Blast now deals additional damage scaling with your attack power". The tooltip
  states no figure; the server's 0.25 x AP (`AscensionSunClericContracts.cpp:309-310`) has no source. No judge proved
  "the gain exists and grows with attack power" without an expected figure.

## Options

- One new kind per need, copying the residual and rate code.
- Opt-in fields on the existing proc and cooldown reset judges, reusing `procs.residual_sizing`, plus one new kind for
  the direction claim.

## Decision

The second option. Every field is optional; without it, model, contract and verdict text stay byte-identical (the
finished-class snapshots regenerate unchanged).

- `residual_target` and `min_detectable` on `cooldown_reset_rate` and `swing_reset_rate` entries go through
  `procs.residual_sizing` (ADR 0781): the judge takes Wilson at `residual_z(target)`, the minimum trials are the larger
  of the band's and the residual's, and the verdict appends `residual_note`.
- `cooldown_reset_rate` takes `reset_between_attempts` (a harness `reset_cooldown` of the trigger before each cast),
  `base_mana_per_attempt` (`hits.base_mana_steps`, which lifts the percent-cost refusal only when set) and
  `trial_casts` (the trials are the trigger's `spell_cast_count`). When the reset fixture's spell is the counted
  row, the control must read exactly one packet per fixture reset, else alert ("fixture packets not 1:1"), and the
  treatment fixture resets are subtracted from the packets.
- A proc entry with `trial: "effective_heal"` (a cast trigger at the ally) counts the trigger's heals on the ally
  only (`spell_heal_count` with `target` ally). The ally is set to 1 health of a 2,000,000,000 maximum before every
  cast, so each of its heals is effective; the caster stays at full health, so a chained heal of it is not effective
  and does not roll. The overheal on the ally and the caster's effective healing of the trigger are read at the end of
  each part; either above 0 makes the verdict `unmeasured`. A chain heal (`TARGET_UNIT_TARGET_CHAINHEAL_ALLY`) is
  accepted as an ally trigger only with this trial.
- A new kind `power_term_direction` casts the spell in four arms (without the passive at base and raised attack power,
  with the passive at raised and base attack power), the attack power read before each arm and every non-critical hit
  one sample. It judges the interaction `(learned high - control high) - (learned low - control low) > 0` at one-sided
  z 3.09 (Welch standard error) and alerts when the control arms change with attack power: the term belongs to the
  passive. `ok` says "direction only: no figure judged"; an entry with an expected figure or a quote with a figure is
  refused (a figure goes to `stat_gain` or `hit_ratio` with its own proof).

## Consequences

- Sun Cleric entries: 704920 x2 (procs), 300367 x2 (`cooldown_reset_rate`, Horusath Blast 572801 and Rapture
  806477), 806699 (`swing_reset_rate`) and 680656 (`power_term_direction`, attack power aura 35785).
- The residual sizing does not shorten a run: the band's own minimum still applies.
- The direction judge's false alert rests on the measured spread and is printed as the z of the interaction; the
  0.25 x AP stays an owner observation.
- Not checked: whether the server's chain-heal target search ever picks a full-health caster; the caster guard read
  makes it visible instead.
