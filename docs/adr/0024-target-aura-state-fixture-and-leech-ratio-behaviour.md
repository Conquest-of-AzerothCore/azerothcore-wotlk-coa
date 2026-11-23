# 0024. A DBC-driven `TargetAuraState` health fixture, and a `leech_ratio` behaviour kind for same-cast effect ratios

- Status: accepted
- Date: 2026-11-07

## Context

Round 2 picked up Titanstrike (806521/806834/806835) and Titanfall 300607. Every Titanstrike scenario in the
previous full run failed its cast with `SPELL_FAILED_TARGET_AURASTATE` (111, `templar/run2/alerts.tsv:387-390`):
`Spell.dbc`'s `TargetAuraState` field on all three ranks is 13 (`AURA_STATE_HEALTHLESS_35_PERCENT`), which
`SpellInfo::CheckTarget` (`SpellInfo.cpp:2142-2143`) requires the target to hold. This is not a settable aura:
`Unit::Update` (`Unit.cpp:735`) recomputes it every tick from `HealthBelowPct(35)`, and no scenario in the package
ever lowered a target's health, so the gate never passed. This blocked two independent checks on the same spell: the
`cooldown_ms`/`power_cost` no-combat checks in `value_scenario`, and the `hit_mean` check in `hit_parts`, plus a
third effect entirely: `hit_kind` did not recognise `SPELL_EFFECT_HEALTH_LEECH` (9, Titanstrike's own effect 0) as a
hit-producing effect at all, independently of the cast failure.

Titanfall 300607 is a plain `SPELLMOD_VALUE_MULTIPLIER` `ADD_PCT_MODIFIER` passive on Titanstrike's family mask
(`EffectBasePoints` 99, +100%), already correctly read as `unmodelled: no own token and no sibling token with equal
points` by the existing token-based passive pipeline (its tooltip, "now heals you for twice the damage dealt", has
no `$`-token) - the disposition `design.md` already named once Titanstrike becomes castable.

## Considered options, the health fixture

1. A per-spell hardcoded scenario step keyed by spell id. Rejected: every other fixture in this package
   (`required_aura_steps`, `CasterAuraSpell`) is read from a DBC field general to any rank, not hardcoded per spell;
   a hardcoded id would not generalise to the next class whose spell carries a different `TargetAuraState`.
2. A generic, DBC-driven fixture keyed by the `TargetAuraState` value itself, with an explicit map from known values
   to a scenario shape and an `Unmodelled` alert for any value the map does not cover. Chosen: the field is already
   read correctly (`SpellInfo::CheckTarget`), the map has exactly one entry today (13 -> 30% health, strictly below
   the 35% gate and above the 20% gate `AscensionTemplarAbilities.cpp:127-129`'s unrelated `+25%` damage conditional
   also checks, so the fixture is robust to that conditional's own `known_auras` state), and an unmapped value alerts
   rather than silently producing a scenario that always fails its cast (the phase-3 "absent effect reads as ok"
   failure mode this package's hard rules forbid).

## Decision, the health fixture

- `values.py` gains `RankFacts.target_aura_state` (from `Spell.dbc`'s own field), `AURA_STATE_HEALTHLESS_35_PERCENT`
  (13), `TARGET_HEALTH_FIXTURES` (`{13: 30}`) and `required_target_health_steps(facts, target=TARGET)`: `[]` when
  `target_aura_state` is 0 (every spell that does not use this gate), the `set_health_pct` + 1000 ms `wait` pair
  (long enough for `Unit::Update`'s per-tick refresh) for a mapped value, and `Unmodelled(f'target aura state {n}
  has no scenario fixture')` for anything else.
- The `Unmodelled` exception moves from `hits.py` to `values.py` (re-exported from `hits` unchanged for every
  existing importer) so `values.py` can raise it without an import cycle back into `hits.py`, which already depends
  on `values.py`.
- The fixture is called once per scenario, before the cast loop, in both call sites that cast a hostile rank:
  `hit_parts` (between the target-measurement steps and `cast_steps`, which loops) and `value_scenario`'s own
  single-cast flow (for `cooldown_ms`/`aura_amount`). `set_health_pct` cannot raise health (`CoAGameplayTest.cpp:
  7440`), so it is issued once, never inside a loop that casts more than once against the same target - the earlier
  `hit_parts` sketch that would have called it per-part is instead called once per part, before that part's own
  cast loop, since each part is its own fresh scenario with a fresh target.

## Considered options, Titanstrike's own hit kind and Titanfall's ratio check

1. Leave `SPELL_EFFECT_HEALTH_LEECH` unmodelled and judge Titanfall only through the existing token-based passive
   pipeline. Rejected: that pipeline already (correctly) calls Titanfall `unmodelled` for lacking its own token,
   and no other check would ever measure Titanstrike's hit or Titanfall's actual effect once the cast fixture
   above unblocks the cast - the result would be a castable spell with no judged behaviour at all.
2. Reuse `healing_ratio_scenario` (`behaviour_ratio`, `kind: "ratio"`) for Titanfall, naming Titanstrike as a
   healing-ratio target. Rejected on two counts: its probe metric is `spell_healing_done`, a no-combat
   `SpellHealingBonusDone` read that never reaches `SpellEffectInfo::CalcValueMultiplier`, the pipeline a
   `SPELLMOD_VALUE_MULTIPLIER` passive actually modifies, so the probe would report ratio 1.0 regardless of whether
   Titanfall works (a false `ok`); and its cast always targets the caster, which `CheckTarget` rejects outright for
   a `TARGET_UNIT_TARGET_ENEMY` effect before even reaching the aura-state gate.
3. Recognise `SPELL_EFFECT_HEALTH_LEECH` as its own `hit_kind` (parallel to `SCHOOL_DAMAGE`), and add a new
   `leech_ratio` behaviour kind that casts the rank for real, once before and once after the passive is learned,
   measuring the real `spell_damage_total`/`spell_heal_total` of each cast. Chosen.

## Decision, `leech` hit kind and `leech_ratio` behaviour

- `hits.py` gains `HEALTH_LEECH = 9` and a `hit_kind` branch parallel to `school`'s; no other part of the hit-model
  pipeline keys on `SCHOOL_DAMAGE` specifically; `applicable()`'s default ("not a heal kind, so `damage`") already
  routes a `leech` hit through the damage-side modifiers and mitigation `SCHOOL_DAMAGE` uses, which is correct:
  `SPELL_EFFECT_HEALTH_LEECH` goes through the same `SpellDamageBonusDone`/`Taken`/mitigation path as a direct hit
  (`Spell.cpp:2929`, "xinef: health leech handling").
- `behaviours.py` gains `LeechRatioSpec` (`spell`, `name`, `quote`, `target_rank`, `expected_before`,
  `expected_after`) and `leech_ratio_scenario`, dispatched from `behaviour_scenario` on `entry['kind'] ==
  'leech_ratio'`. It declares two separate dummy fixtures ("before"/"after": `set_health_pct` cannot raise health
  back up, so the same dummy could not take a second cast once the fixture or the first cast's leech has already
  lowered it), casts the rank once at each, and measures `spell_damage_total` (on that phase's dummy) and
  `spell_heal_total` (always on the caster: `HealBySpell(m_caster, m_caster, ...)` heals the caster regardless of
  the cast's target) of that one cast.
- Measuring the real combat values this way surfaced two effects the design pass did not anticipate, both confirmed
  by an actual gameplay run before being corrected (never guessed):
  1. `spell_heal_total` (`CoAGameplayTest.cpp`) sums every matching heal event since the scenario started, not
     since the last measurement, so the "after" phase's raw reading also carries the "before" phase's heal (both
     casts heal the same caster with the same spell id). `compare.py`'s new `behaviour_leech_ratio_verdict`
     subtracts a `heal_baseline_label` (the "before" phase's own heal label; absent, i.e. zero, for the "before"
     phase itself, which is naturally the scenario's first heal event) before computing the ratio.
  2. `Spell.cpp`'s health-leech handling computes the heal from `damageInfo.damage`, which already carries the
     reference character's own damage-done percent modifiers (`known_auras`, aura 341), then applies the
     healing-done percent modifiers of the *same* auras again on top (aura 136, through `SpellHealingBonusDone`/
     `Taken`) before calling `HealBySpell`. The two percents do not cancel against the recorded damage total:
     the ratio actually measurable is `healMultiplier x heal_done_factor`, not `healMultiplier` alone (confirmed
     empirically against the Templar's own `known_auras` 887007, -20%/-20%: measured ratios 0.8 and 1.6 against a
     raw 1.0/2.0, matching the factor exactly once the cumulation above is also corrected). `behaviours.py` gains
     `leech_heal_modifier_factor(records, class_file)`, folding every known `heal`-side `Modifier`
     (`hits.aura_modifiers`) into `expected_before`/`expected_after` at scenario-build time - the same discipline
     `rank_hit` already applies to fold known auras into a `hit_mean` model, so the expected value stays
     DBC-plus-known-modifier derived, never invented, and the check still fails (`alert`) if the doubling is
     absent or broken, which `test_compare.py`'s regression (`'heal' == 'damage'` against an `expected` of 2.0)
     proves.
- `compare.py` gains `behaviour_leech_ratio_verdict`, reusing `behaviour_ratio_verdict`'s delta-on-the-damage-scale
  judging (`delta_status`/`delta_margin` keyed by the shared `BEHAVIOUR_RATIO` tolerance) once the baseline
  subtraction above is applied; `judge_behaviour` dispatches to it when `model['kind'] == 'leech_ratio'`, keeping
  the `Expectation.check` itself `BEHAVIOUR_RATIO` (so existing counting/filtering by check name is unaffected).

## Consequences

- Titanstrike's `cooldown_ms`/`power_cost`/`effect_value` checks and its `hit_mean` check all read `ok` in the
  scenarios this round generated and ran, where every one previously read `unmeasured: cast failed:
  SPELL_FAILED_TARGET_AURASTATE (111)` or `unmodelled: no damage or healing effect`.
- Titanfall 300607 gets a real `ok` verdict (ratio 0.8 -> 1.6 against the Templar reference character's own known
  modifiers, 1.0 -> 2.0 before them) in place of its previous, correctly-conservative `unmodelled`.
- `required_target_health_steps` is safe for every other class's hostile scenarios: it returns `[]` whenever
  `TargetAuraState` is 0, the common case, so no existing scenario changes shape.
- A fifth behaviour shape ("ratio of two different-kind effects within one real cast") now exists alongside
  `count`/`ratio`/`spread`/`trigger`/`metric_delta`; a future passive whose claim is a same-cast heal:damage (or
  similarly paired) ratio reuses `leech_ratio_scenario`'s dummy-per-phase and baseline-subtraction pattern rather
  than adding a sixth. A reader of `verdicts.json` should not assume `leech_ratio`'s `expected` field is the raw
  DBC multiplier: it is that multiplier folded with the reference character's own known heal-done modifiers, by
  design, the same way a `hit_mean` model's `reference.mean` is never the bare tooltip value either.
