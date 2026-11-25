# 1300. An effectiveness delta can read attack power

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39
- Builds on: ADR 0601, ADR 0671, ADR 1160, ADR 1275

## Context

Cultist (class 25) talent Improved Sermon of Dread 706177 (row 300) states:

> "Increases the effectiveness of Sermon of Dread by $s1%."

`Spell.dbc` 706177 carries `Effect[0]` aura 108 (`SPELL_AURA_ADD_PCT_MODIFIER`, `MiscValue = 3` `SPELLMOD_EFFECT1`,
`BasePoints = 39 + DieSides = 1` = `+40%`) on `EffectSpellClassMask[2] = 0x10000000`, matching Sermon of Dread 620614
(`SpellFamilyFlags[2] = 0x10000000`, `Effect[0]` aura 344 `SPELL_AURA_ASCENSION_MOD_ATTACK_POWER_FLAT`,
`BasePoints = -141 + DieSides = 1 + RealPointsPerLevel = -1.0 * (60 - 56)` = `-144` attack power on nearby enemies for
30 s).

`CoAGameplayTest.cpp:4076` already reads `attack_power` on any unit including `dummy`, and `metric_delta_spec` already
supports `measure_actor: "dummy"`, but `effectiveness_delta.READ_METRICS` lacked `'attack_power'`, so a plain
`metric_delta` reading `attack_power` was classed `data` because the claim lacks the promise words `"attack power"`.

## Decision

Add `'attack_power'` to `kinds/effectiveness_delta.py` `READ_METRICS`. This registers `'effectiveness_attack_power'` in
`METRIC_EVIDENCE` (`'state'`) and `STATE_PROMISES` (`r'effectiveness'`), matching the existing `spell_power`, `stat`,
`dodge_chance`, `parry_chance`, `run_speed_rate` and `resistance` entries.

## Evidence class

`effectiveness_attack_power` is a `STATE` metric under `LEARNED_CONTRAST` (the debuff spell is cast for real before and
after learning the modifier talent, and the debuffed unit's live `attack_power` is read in both phases) promised by the
word `effectiveness` — genuine `behaviour` evidence.

## Consequences

- Opt-in only; finished classes regenerate byte-identical.
- Closes Cultist Improved Sermon of Dread 706177 row 300: Sermon of Dread 620614 cast at a `dummy` buffed with Attack
  Power 980 (`35785`, preventing zero-clamping) reduces the dummy's attack power by `-144` without 706177 and by
  `int32(-144 * 1.40) = -201` with 706177 (additional drop `expected_gain = -57`, tolerance `0.5`).
- `test_effectiveness_delta.test_a_dummy_attack_power_debuff_is_judged_as_its_effectiveness_state` covers generation,
  `ok`, unmodified/wrong-gain alerts, `unmeasured` on missing read, promise matching and refusal without the metric.
