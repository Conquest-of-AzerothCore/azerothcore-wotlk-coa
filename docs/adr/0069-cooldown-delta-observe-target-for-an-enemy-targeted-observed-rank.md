# 0069. `cooldown_delta` entries can cast the observed rank at a named target

- Status: accepted
- Date: 2026-11-10

## Context

Every pre-existing `cooldown_delta` entry observes a Libram's own cooldown (801461, Libram of Tenacity): a
self-only cast with `EffectImplicitTargetA[0]` `TARGET_UNIT_CASTER`, so `cooldown_trial_steps` casting it with
no explicit target (`cast_steps(..., None, ...)`) always succeeds, and the cast carries no global cooldown
(`StartRecoveryTime` 0), so nothing needs to be waited out between it and the trigger cast that follows.

Libram of Zeal (801466) reduces the cooldown of Righteous Upheaval instead, read directly from
`AscensionTemplarEvents.cpp`'s `case 801466: Reduce(player, 501562, std::abs(Amount(575328)));`. Proving this
clause surfaced four real gaps, each confirmed by a real gameplay run before being closed, none of them
server defects:

1. 501562 (`SPELL_EFFECT_SCHOOL_DAMAGE`, `EffectImplicitTargetA[0]` `TARGET_UNIT_TARGET_ENEMY`) needs an
   explicit hostile target to pass `Spell::CheckCast`; casting it with no target failed
   `SPELL_FAILED_BAD_TARGETS` on every attempt (`cast_failures` reason 12).
2. `Reduce()` matches by `Named()` (same `spell_ranks` chain), on whichever rank the player actually has in
   `GetSpellMap()`; naming the chain's rank-1 id (501562) as the entry's own `observe_spell` measured a flat,
   unmodified decay on every trial, because nothing ever puts 501562 itself into `GetSpellMap()` for the
   reference character (whose own known rank is 572027, rank 7 of the same chain,
   `rev_20260831_01_local_spell_progression.sql:293-299`): `Player::ModifySpellCooldown` finds no
   `m_spellCooldowns` entry for 501562 and silently returns. Observing 572027 (the rank the reference
   character actually knows, and the same rank every other entry in this file already uses for "Righteous
   Upheaval"/"Oath Breaker") fixed this.
3. 572027 carries its own global cooldown (`StartRecoveryCategory` 133, `StartRecoveryTime` 1000 ms), which
   `cooldown_trial_steps` had no wait for between casting it (to arm the "before" cooldown reading) and
   casting the trigger spell right after: the trigger cast failed `SPELL_FAILED_NOT_READY` on every attempt
   while still on the shared GCD.
4. Condemn (804906), the first trigger spell tried, is itself `SPELL_AURA_PERIODIC_DAMAGE` (a DoT): every one
   of its proc events carries `periodic=true`, which `case 801466`'s own `!periodic` term rejects outright, so
   it can never trigger this clause at all, confirmed with a temporary, reverted `LOG_ERROR` trace. Holy Cleave
   (801445, `SPELL_EFFECT_NORMALIZED_WEAPON_DMG` + `SPELL_EFFECT_WEAPON_PERCENT_DAMAGE`, melee damage class) is
   a direct, non-periodic hit instead, but most of its non-crit hits read exactly 0 damage against the dummy
   fixture (mitigation), so most attempts were not valid trials of the clause either, confirmed the same way.

## Decision

Four additive fields/fixes on `cooldown_delta`, none changing an existing entry's behaviour:

- `observe_target`: `"self"/"dummy"/"ally"`, the same vocabulary `TRIGGER_TARGETS` already uses for the
  trigger's own `target`. `checked_cooldown_entry` validates it against `TRIGGER_TARGETS` when present.
  `cooldown_trial_steps` resolves it the same way `cooldown_trigger_scenario` already resolves
  `trigger['target']` and passes it to the observed rank's own `cast_steps` call; omitted, the observed rank
  is cast with no target exactly as before. `cooldown_trigger_scenario`'s creature-fixture condition gains
  `entry.get('observe_target') == TARGET` alongside its existing `trigger.action == ATTACK or
  trigger.target == TARGET` check.
- A wait of `observe_interval` (the observed rank's own `cast_interval`) between the "before" cooldown reading
  and the trigger cast, added only when `observe_target` is set (a target-free observed cast, like every
  existing Libram, needs no such wait). `attempt_interval`'s own `COOLDOWN_DELTA_KIND` branch reserves this
  same amount a second time when `observe_target` is set, since the per-trial spacing wait at the end of
  `cooldown_trial_steps` already reserves one `observe_interval`; without doubling the reservation, five parts
  of real attempts ran the scenario past its own declared `timeout_ms` and the run failed outright with
  "Scenario timed out during setup or execution" (confirmed by a real run before this fix).
- `force_crit`: `"melee"/"spell"`, the same field `trigger_scenario`/`magnitude_ratio_scenario` already
  support. `cooldown_trigger_scenario` never applied it at all (a real gap, not specific to this entry); it now
  sets the player fixture's crit rating the same way the other two scenario builders do.
- `cooldown_trial_steps` skips a `setup_casts` spell during the baseline phase when that spell equals the
  entry's own `aura`. Every pre-existing `setup_casts` use names a *different* spell from `aura` (Eternally
  Devoted 573452's `setup_casts: [705300]`), so casting it during baseline is harmless (the real gate is
  `aura` itself, withheld correctly). 801466 needs `setup_casts: [801466]` (it is not
  `SPELL_ATTR0_PASSIVE`: `learn` alone never applies its aura, so it must be freshly cast every trial), which
  makes `aura` and the `setup_cast` the same id; the scenario's own unconditional `learn(setup_casts)` step at
  the very top (needed so the baseline phase can cast it at all) already taught 801466 before baseline ran,
  and `cooldown_trial_steps`'s per-trial loop cast it during baseline too, so "without the passive" measured
  the effect anyway: a real baseline alert (`cooldown delta 3518 ms ... in a baseline trial without the
  passive`) confirmed this before the fix.

## Considered options

1. Pick a different trigger spell for 801466 whose own cooldown-reduction target is self-castable and whose
   damage is never periodic or mitigated to zero. Rejected for the *observed* side: the server code names
   572027's own rank chain explicitly; proving the real clause means observing the rank the reference
   character actually has. For the *trigger* side, this is exactly what happened (Condemn to Holy Cleave).
2. Give `cooldown_trial_steps` a fixed hostile-target cast for every entry, dropping the self-cast path.
   Rejected: every other `cooldown_delta` entry observes a Libram that must stay a self-cast (a hostile cast
   of a self-only buff would itself fail `CheckCast`), so the field needs to be opt-in per entry, not global.
3. Let `setup_casts` spells run during baseline unconditionally, as before, and instead give 801466 a second,
   synthetic `aura`-like id. Rejected: it would misrepresent which spell the DBC/server code actually tracks,
   and the ordinary `aura == setup_casts[0]` case is exactly the shape worth supporting directly.

## Consequences

A `cooldown_delta` entry can now observe a rank whose own effect needs an explicit target, force a crit on its
trigger cast, and arm its own non-passive aura via `setup_casts` without that arming leaking into the
baseline. `checked_cooldown_entry` gained a new failure mode (`observe_target` not one of `TRIGGER_TARGETS`,
and the pre-existing `force_crit`/`setup_casts` checks now apply to an entry that also sets `observe_target`)
with seeded-bad-value unit tests; direct `cooldown_trial_steps`/`cooldown_trigger_scenario` tests prove the
target, wait, baseline exclusion and crit rating are each applied only when their field is set.
