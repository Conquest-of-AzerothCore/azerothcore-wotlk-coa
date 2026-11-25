# 1305. Two-rate non-zero baseline contrast in cooldown_reset_rate

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Builds on: ADR 0603 (`cooldown_reset_rate`), ADR 0781 (`residual_sizing`), ADR 1192 (cooldown-reset options)

## Context

Cultist Horrific Visions 707753 states "While above 40 Insanity, your chance to trigger Dark Revelation is now
increased by $s1%." (`Spell.dbc` Effect[0] aura 107 `BasePoints = 9, DieSides = 1 -> +10%`, `MiscValue = 23`). In
`AscensionCultist.cpp:112-113`, `Chance()` adds `Amount(707753)` to Dark Revelation `300313` (`ProcChance = 6%` ->
`16%`) and `706245` (`20%` -> `30%`) when `Count(player, Insanity) > 40 && player->HasAura(707753)`.

No existing conformance kind could express this claim:
- `procs.py` accepts only `SPELLMOD_CHANCE_OF_SUCCESS` (op 18), refusing 707753 (`MiscValue = 23`).
- `cooldown_reset_rate.py` learns only `trigger_spell` and `reset_spell` before control and hard-alerts on any control
  reset (`control_resets != 0`), so a talent boosting an existing 6% baseline proc cannot be tested.
- `flat_chance_rate.py` counts cast/summon events, whereas Dark Revelation emits `SMSG_CLEAR_COOLDOWN` (`0x1DE`).

## Options

- Add a brand-new check kind duplicating `cooldown_reset_rate`'s packet reads, pooling and residual sizing. Refused:
  needless duplication.
- Extend `cooldown_reset_rate` with opt-in `base_learn`, `control_chance_pct` and `control_attempt_auras`, splitting
  the per-pair residual target across both arms and enforcing strict separation of learned and condition contrasts.
  Chosen.

## Decision

`kinds/cooldown_reset_rate.py` gains three opt-in fields (all absent by default):

- `base_learn`: non-empty list of distinct positive prerequisite spell ids learned before control (not repeating
  `trigger_spell` or `reset_spell`).
- `control_chance_pct`: expected baseline rate in `(0, 100)` during control; requires `base_learn` and strictly
  disjoint G-20 bands from `chance_pct` (`|chance_pct - control_chance_pct| > band(control) + band(treatment)`). When
  `residual_target` and `min_detectable` are set, the per-pair target splits equally across both arms (per-arm Wilson
  confidence `1 - target / 4`, `z = residual_z(target / 2)`), so the combined union bound over 2 arms x 2 runs stays
  at or below `residual_target`. Both `control_casts * parts` and `casts * parts` must meet their arm's minimum trials.
- `control_attempt_auras`: caster auras set before each control cast instead of `attempt_auras`. Permitted only when
  `talent` is in `base_learn` and `control_attempt_auras != attempt_auras` (pure condition contrast, no second `learn`
  between arms). Refused when `talent` is not in `base_learn` (pure learned contrast, identical auras in both arms),
  preventing two-variable confounding.
- In `cooldown_reset_rate_pooled_verdict`, when `control_chance_pct` is present in the model, both control and
  treatment rates are judged with `rate_judgement` and `banded_rate`, and their Wilson intervals must be strictly
  non-overlapping in the expected direction (`control_high < treatment_low` for an increase, else alert).

## Statistical Sizing (Cultist 707753 on 300313: 6% -> 16%)

At `residual_target = 0.001` per pair and `min_detectable = 4` points, per-arm confidence is `0.99975` (`z = 3.6623`),
requiring at least `7,565` control trials and `18,026` treatment trials. Over `9` pooled parts (`1,000` control casts
and `2,200` treatment casts per part, `9,000` control and `19,800` treatment hits total):
- Control `6%` in G-20 band `[4%, 8%]`: exact binomial false-fail `1.024e-4`/run (`2.049e-4`/pair); false-pass if true
  rate is `16%` or `±4` pts off is `< 1e-11`.
- Treatment `16%` in G-20 band `[14%, 18%]`: exact binomial false-fail `7.762e-5`/run (`1.552e-4`/pair); false-pass if
  true rate is `6%` or `±4` pts off is `< 1e-11`.
- Combined pair union-bound false-fail probability: `3.601e-4` (`0.036% <= 0.1%`).

## Consequences

- Closes Cultist Horrific Visions 707753 rows 335 (`threshold_40`, 40 vs 41 Insanity condition contrast) and 336
  (`above_40_learned`, unlearned vs learned contrast at 41 Insanity).
- Single-rate entries without `base_learn`/`control_chance_pct`/`control_attempt_auras` regenerate byte-identical.
