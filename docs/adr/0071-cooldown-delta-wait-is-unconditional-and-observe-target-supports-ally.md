# 0071. `cooldown_delta`'s observe-cast wait is unconditional, and `observe_target` groups an ally

- Status: accepted
- Date: 2026-11-10

## Context

ADR 0054 added a wait of `observe_interval` between the observed rank's "before" cooldown reading and the
trigger cast, but only `if entry.get('observe_target')`: at the time, the only known-GCD-bearing observed rank
(572027, Righteous Upheaval) also happened to need an explicit hostile target, so the two conditions coincided
and the narrower one was shipped.

One With The Light (504807) effect 0 (`for (uint32 root : {500694, 806153, 801455}) Reduce(player, root, 1000);`,
`AscensionTemplarAbilities.cpp:186-189`) needed all three of its named spells proven, and the three expose every
combination ADR 0054's coincidence hid:

- Force of Golganneth (500694, `EffectImplicitTargetA[0]` `TARGET_UNIT_CASTER`, confirmed via `coa-dbc-viewer`)
  self-casts fine and so takes no `observe_target` at all, but its own `StartRecoveryTime` of 1250 ms
  (`coa-dbc-viewer`) still locks the player's global cooldown. With the old conditional wait, the
  immediately-following, zero-wait trigger cast failed `Spell::CheckCast`'s `HasGlobalCooldown` check with
  `SPELL_FAILED_NOT_READY` (67) on most attempts, reproduced in a prior round's own run (162 of 244 trigger
  casts failed this way, diluting the measured delta to 17.996 ms against the expected 1000 ms).
- Divine Force (806153, `EffectImplicitTargetA[0]` `TARGET_UNIT_TARGET_ENEMY`) needs `observe_target: "dummy"`,
  the case ADR 0054 already covers.
- Testament of Will (801455, `EffectImplicitTargetA[0]` `TARGET_UNIT_TARGET_ALLY`) needs `observe_target:
  "ally"`, a case ADR 0054 added to `checked_cooldown_entry`'s accepted vocabulary (`TRIGGER_TARGETS`) but
  never exercised: `cooldown_trigger_scenario` only grouped an ally player for `trigger.get('target') ==
  ALLY`, never for `entry.get('observe_target') == ALLY`, so casting 801455 at `"ally"` would have failed with
  no grouped ally present.

Three entries for the same aura (504807) and the same `effect` (0) also surfaced a second, independent gap:
`conformance.py`'s `add_trigger` keys a scenario filename by `(aura, effect)` whenever `effect` is set, with no
further disambiguation for `cooldown_delta` — unlike `shares_trigger_aura`'s existing per-trigger-spell
disambiguation (ADR 0053) and `cooldown_label`'s own per-`observe_spell` disambiguation (pre-existing, used
when `shares_cooldown_aura` is true). Generating all three new entries together raised `ValueError('Duplicate
scenario key conformance-templar-trigger-504807-0-part-1')` the first time a second effect-0 part was written,
confirmed by running `generate()` before this fix.

## Decision

- `cooldown_trial_steps` now waits `observe_interval` before the trigger cast unconditionally, regardless of
  whether `observe_target` is set. `attempt_interval`'s `COOLDOWN_DELTA_KIND` branch reserves this same amount
  twice unconditionally too (previously the second reservation was also gated on `observe_target`), keeping the
  scenario budget consistent with what `cooldown_trial_steps` now always schedules. The added wait is small
  (an idle `cast_interval(observe_spell)`, as little as `CAST_MARGIN_MS` for an instant, no-GCD observed rank
  like 801461) and does not change any already-passing entry's measured delta, only its schedule.
- `cooldown_trigger_scenario` groups an ally (`{'action': 'group', 'actor': CASTER, 'target': ALLY}`) and adds
  the ally player fixture when `trigger.get('target') == ALLY` **or** `entry.get('observe_target') == ALLY`
  (previously only the former).
- A new `shares_cooldown_effect(class_file, entry)` (`triggers.py`), counting `cooldown_delta` entries sharing
  both `aura` and `effect`, mirroring `shares_cooldown_aura`'s shape. `conformance.py`'s `add_trigger` appends
  `entry['observe_spell']` to `key_parts` when a `cooldown_delta` entry's `(aura, effect)` key collides this
  way, the same disambiguation `cooldown_label` already applies to the human-readable verdict label.

## Considered options

1. Keep the wait conditional on `observe_target` and give Force of Golganneth a separate, synthetic
   `observe_target: "self"` just to trigger the wait. Rejected: `"self"` is already a valid `TRIGGER_TARGETS`
   member with a different meaning (an explicit self-cast, which `cast_steps` would then pass as a literal
   target string instead of casting with no target at all, changing the scenario's semantics for no reason);
   the actual distinguishing fact is the observed rank's own GCD, not its target, so the wait should be keyed
   on that, and the simplest sound rule is to always wait rather than inspect `StartRecoveryTime` from the
   entry schema.
2. Key scenario filenames by `(aura, effect, observe_spell)` unconditionally whenever `effect` is set, instead
   of only when a real collision exists. Rejected: it would silently rename every existing effect-keyed
   scenario file's path, for no benefit where no collision exists today; disambiguating only on an actual
   collision (mirroring `shares_trigger_aura`'s own precedent) keeps stable names stable.

## Consequences

`cooldown_delta` entries can now observe a self-casting rank with its own GCD, a hostile-targeted rank, or an
ally-targeted rank, including several such entries sharing one aura and effect index, without a scenario-key
collision. `test_triggers.py` gained `CooldownDeltaObserveTargetTest`'s updated self-cast case (now asserting
the wait IS present, replacing the old assertion that it was absent), `OneWithTheLightCooldownEntryTest`'s
three-entry/ally-group/creature-fixture cases, `CooldownDeltaLabelDisambiguationTest`'s
`shares_cooldown_effect` true/false/sole-entry cases, and `GenerateTriggerTest`'s
`test_one_with_the_light_cooldown_scenario_keys_do_not_collide`, a `generate()`-based regression that fails
with the pre-fix `ValueError` if the `add_trigger` disambiguation is reverted.
