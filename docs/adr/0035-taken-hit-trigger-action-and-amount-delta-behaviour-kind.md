# 0035. A `taken_hit` trigger action and an `amount_delta` behaviour kind

- Status: accepted
- Date: 2026-11-09

## Context

`round4/trigger-lot-r4-5-spec.md` found two of the lot's ten spells genuinely missing a `triggers`/`behaviours`
entry (the other eight already had one, confirmed by checking `classes/templar.json` directly rather than the
family-default `unmodelled` line every effect with `EffectApplyAuraName` 42/354/23/231 carries regardless):

- Sacred Defense 705306 ("When you take Physical damage you now strike back..."): reachable through an explicit
  `spell_proc`/`spell_script_names` pair (`rev_20260909_04_templar_completion.sql`), not the raw, dead DBC
  `EffectTriggerSpell[0]`. The condition is a hostile hit *landing on* the caster, the reverse of every
  existing `triggers.py` action, all of which have the caster act (`cast`, `attack`, the aura's own `periodic`
  tick).
- Holy Books 706468 ("Using a Libram now removes 70% of the delayed damage from Oathkeeper"):
  `AscensionTemplarAbilities.cpp`'s `OnSpellCast` calls `ReduceDebt(player, 70)` (the same function 712346
  Sacred Oath's existing `duration` kind already measures, non-`oneTick` branch) when a Libram is cast and
  706468 is known. This is an *amount* delta around a different spell's cast, not a count, ratio, duration or
  metric-delta shape any existing kind covers.

## Considered options (trigger action)

1. Reuse `attack`, pointing it at the caster as the victim. Rejected: `attack`'s own shape assumes the caster
   is the attacker (`{"action": "attack", "actor": "caster", "target": "dummy"}`, swing-speed-paced,
   melee-count trial metric); inverting its actor/target meaning in place would silently change what every
   existing `attack` entry means.
2. A new `taken_hit` action, with its own `attempt_interval`/`attempt_steps`/trial-counting branches, leaving
   every other action's code path untouched. Chosen.

## Considered options (behaviour kind)

1. Extend `metric_delta`'s `before_expected`/`expected` to accept a fraction of a measured value instead of a
   fixed constant. Rejected: `metric_delta_scenario` has no mechanism to first *establish* a debt via a striker
   (as `duration_scenario`'s own debt-setup prologue already does) before measuring; bolting that prologue onto
   `metric_delta` would make its existing, simpler no-combat with/without shape conditional on a kind-specific
   fixture, which every other `metric_delta` entry does not need.
2. A new `amount_delta` kind, modelled directly on `duration_scenario`'s debt-setup prologue and
   `duration_refresh_scenario`'s two-phase (without/with) structure, substituting a cast of a *different* spell
   and an `aura_amount` read for the forced-crit swing and `aura_duration_ms` read. Chosen.

## Decision

- `triggers.py` gains `TAKEN_HIT = 'taken_hit'`. `TRIAL_METRICS[TAKEN_HIT] = frozenset({'spell_damage_count'})`.
  `checked_entry` requires a positive `trigger['striker_entry']` for this action. `attempt_interval` returns
  `max(cast_interval(class_file, trigger['spell'], cooldown), 500)` — the striker's own spell's cast time and
  recovery, not the caster's, since the caster never casts anything. `attempt_steps` builds a plain
  `{"action": "cast", "actor": "striker", "spell": trigger["spell"], "target": "caster"}` loop, one cast per
  attempt with no `attack`/`stop_attack` bracket. `count_step` gains an optional `caster` field (a cast query's
  *source* filter, `CoAGameplayTest.cpp`'s `spell_damage_count` metric already supports it) and a `target`
  parameter in place of the hardcoded `TARGET`; `counts()` reads the trial count with `actor: "caster"`,
  `caster: "striker"`, `target: "caster"` — the harness can only read a combat-log metric from a player actor
  (`run.py`'s `metric needs a player` rule), so the query is framed as "the caster's own log, filtered to hits
  from the striker", not "the striker's own log" (which does not exist; creatures have no session to observe
  packets through). `trigger_scenario` adds a `striker` creature (reusing `behaviours.py`'s `STRIKER`/
  `STRIKER_HEALTH`/`STRIKER_DISTANCE`, `reaction: 0`, `stationary: true`) instead of the usual `dummy` fixture
  when the action is `taken_hit`.
- `behaviours.py` gains `BEHAVIOUR_AMOUNT_DELTA = 'behaviour_amount_delta'`, `'amount_delta'` in `KINDS`, an
  `AmountDeltaSpec` (`fraction`, `target_aura`, `debt_aura`, `breaker_spell`, `striker_entry`, `trigger_spell`,
  `mechanism_file`, `reduce_function`) and `amount_delta_scenario`/`amount_delta_spec`, dispatched from
  `behaviour_scenario`. Each of its two phases (`without`/`with`, one scenario) independently re-establishes a
  fresh debt (`set_aura` the debt aura, a `striker` casts `breaker_spell` at the caster, asserts the target
  aura's `aura_amount` effect 0 is nonzero — `duration_scenario`'s own `DEBT_ASSERT_TIMEOUT_MS` pattern), reads
  `aura_amount` before, casts `trigger_spell` at self, reads `aura_amount` after.
- `compare.py` gains `behaviour_amount_delta_verdict`, dispatched from `judge_behaviour`: `percent =
  round(fraction * 100)`, `with_expected = with_before - (int(with_before) * percent) // 100` (the server's own
  truncating `uint64` arithmetic, not a float multiply); `ok` only when the without-phase's `after == before`
  exactly and the with-phase's `after == with_expected` exactly.

## Consequences

- Sacred Defense 705306's check measured a genuine shortfall this round (165-174 events against 232-240 trials,
  not the 1:1 the tooltip and the code's own ICD gate would suggest), reproduced across several spacing margins
  (1000 ms and 6000 ms internal-cooldown-equivalent spacing measured similar shortfalls, ruling out a timing/ICD
  overlap as the cause). The spell's own `spell_proc` row restricts the native proc to `HitMask` 35 (`NORMAL` |
  `CRITICAL` | `PARRY`), which excludes a `PARTIAL BLOCK`/`ABSORB`/`FULL_RESIST` hit outcome even when it still
  deals nonzero damage (`Unit.cpp`'s hit-mask assignment); whether the caster's own combat table produces enough
  of those outcomes against a melee-class spell to explain the measured shortfall is not confirmed in this
  session and is left to whoever triages this alert next, per this round's "no new work proposed, flag the
  overlap" precedent for an already-measured finding (section 4 of `trigger-lot-r4-5-spec.md`).
- Holy Books 706468's first measured run (both settle waits at the shared `CAST_SETTLE_MS`, 500 ms) alerted even
  in the without-phase: the target aura (Oathkeeper 803237) carries its own `EffectApplyAuraName[0]` 3
  (`SPELL_AURA_PERIODIC_DAMAGE`) at `EffectAmplitude[0]` 1000 ms, releasing part of its staggered amount on a
  1-second cycle independent of any Libram; `500 + 500 = 1000` ms straddled that cycle on almost every run.
  `AMOUNT_DELTA_CAST_WAIT_MS` (150 ms) replaces the post-cast wait so the total elapsed time from the
  debt-establishing hit to the "after" read stays comfortably under 1000 ms; the re-measured run reads `ok`.
  A future `amount_delta` entry against a *different* periodic debt aura must re-check that aura's own
  `EffectAmplitude` against its total settle-window budget rather than assume 150 ms is always safe.
- This action/kind pair only covers a hostile creature's own direct-damage cast landing on the caster, and an
  amount reduction read around a different spell's cast. A `taken_hit` trigger whose breaker spell needs a
  precondition this harness's `TRIGGERED_FULL_MASK` creature cast does not bypass (confirmed for
  `CasterAuraState`, by reproduction: Revenge 6572 failed `SPELL_FAILED_BAD_TARGETS` even triggered) needs a
  different breaker spell chosen per entry, not a harness change.
