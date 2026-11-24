# 1192. Rate judges take a residual, heal trials and fixture resets; a power term is judged by its direction

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Supplements [ADR 0603](0603-a-cooldown-reset-is-counted-from-its-clear-cooldown-packet.md),
  [ADR 0720](0720-a-cooldown-reset-rate-can-pool-identical-cases.md),
  [ADR 0781](0781-a-proc-rate-can-be-sized-for-a-per-pair-residual-target.md)
  and [ADR 1187](1187-a-cooldown-reset-rate-can-be-counted-from-auto-attack-hits.md)

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
- Odyn's Vanguard 806699: the `swing_reset_rate` kind (ADR 1187) had no residual option.
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
  of the band's and the residual's, and the verdict appends `residual_note`. `residual_target` sizes the false pass
  of a `min_detectable` deviation; the per-pair false alert at the chance stays within the same target only when
  `min_detectable` is at least twice the band (ADR 0781, Witch Hunter 804192), so the Sun Cleric entries take 4
  points against their 2-point band.
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
  one sample. It judges the interaction `(learned high - control high) - (learned low - control low) > 0` against the
  one-sided 99.9% Student t quantile at its Welch-Satterthwaite degrees of freedom over the four arms (Welch standard
  error; z 3.09 at infinite freedom) and alerts when the control growth `control high - control low` reaches the
  two-sided Student t quantile of a 0.05% per-run level (`1 - sqrt(0.999)`) at the control arms' Welch-Satterthwaite
  degrees of freedom (3.83 at 36, z 3.48 at infinite freedom): the term belongs to the passive. `ok` says "direction
  only: no figure judged"; an entry with an expected figure or a quote with a figure is refused (a figure goes to
  `stat_gain` or `hit_ratio` with its own proof). The verdict names its fixtures (the attack power aura and the
  `attempt_auras`, set by harness `set_aura`), and the contract states both levels: the control check's false alert is
  0.05% per run and 0.1% per pair (D-197), and a false pass needs the interaction above its quantile in both runs, at
  most 0.1% per run. The t quantile is `stack.student_t_quantile`, the one the band and exclusion judges use. Mentor
  D-127 replaced the first version's normal quantiles (z 3.09 on both sides: 0.77% per pair for the control at 36
  degrees of freedom, review I-A). A seeded null simulation in the kind's tests (20000 pairs, 10 samples per arm, equal
  spreads) gives 0.055% per pair for the control alert and 0.075% per run for the false pass, against 0.51% and 0.17% at
  the normal quantiles.

## Consequences

- Sun Cleric entries: 704920 x2 (procs), 300367 x2 (`cooldown_reset_rate`, Horusath Blast 572801 and Rapture
  806477), 806699 (`swing_reset_rate`) and 680656 (`power_term_direction`, attack power aura 35785). Each rate entry
  has `residual_target` 0.001 and `min_detectable` 4: at least 19386 trials at 20% and 29078 at 40%, where the
  false alert at the chance is at most 0.1% per pair (normal approximation). 300367 runs 11 parts of 1900 Horusath
  Blast casts and 19 parts of 1050 Rapture casts, 806699 14 parts (the cross-class guard sizes it at the default
  2300 ms weapon) and 704920 188 and 230 parts (the 1.5x outcome margin of the proc plan).
- The rate proves the chance of 704920, not the healing increase of the next Illumination or Radiant Cascade: the
  ledger splits each clause into the chance claim and the increase claim, which stays open.
- The control check of `power_term_direction` meets the 0.1% per-pair false-alert bound of D-197 under the t law;
  the higher quantile lowers only the guard's power.
- The residual sizing does not shorten a run: the band's own minimum still applies.
- The direction judge's levels rest on the Welch-Satterthwaite approximation of the measured spreads; the verdict
  prints each z with its t quantile and degrees of freedom. The 0.25 x AP stays an owner observation.
- Not checked: whether the server's chain-heal target search ever picks a full-health caster; the caster guard read
  makes it visible instead.
