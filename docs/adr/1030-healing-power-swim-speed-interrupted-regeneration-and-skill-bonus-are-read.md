# 1030. Healing power, swim speed, interrupted regeneration and skill bonus are read

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules), ADR 0711 (fields_sum)

## Context

Four Witch Doctor claims are data conformant but have no behaviour read (cycle 10 proposal "harness reads", tool notes
T-b10-1, T-b10-2, T-b10-5 and the cycle 9 Spirit Healer gap):

- Spirit Healer 560280 "Increases healing power by $s1% of Spirit" (aura 175). `spell_power` reads
  `SpellBaseDamageBonusDone` only.
- Mixologist 561069 "by $803269s1% (swim speed)" (aura 58 of the Fish Oil area aura). The harness reads the run and
  flight speed rates, not the swim rate.
- Spiritual Traditions 705911 "Allows $s2% of your mana regeneration to continue while casting" (aura 134). The harness
  reads `mana_regen_interrupted`, but the conformance tool has no evidence row for it, and its value depends on Spirit
  and Intellect, so a stated expectation needs it as a share of `mana_regen` of the same unit.
- Natural Alchemist 536213 "Alchemy skill increased by $s1." (aura 98). `skill_value` reads the pure value, without the
  bonus the aura adds, and the reference character has no Alchemy line for the aura to modify.

## Decision

- Harness reads (`CoAGameplayTest.cpp` `Measure`, `run.py` metrics): `healing_power` (with `school`, a player,
  `Unit::SpellBaseHealingBonusDone`), `swim_speed_rate` (any unit, `Unit::GetSpeedRate(MOVE_SWIM)`) and `skill_bonus`
  (with `skill`, a player that holds the line, `GetSkillPermBonusValue + GetSkillTempBonusValue`: aura 98 adds to the
  permanent bonus, aura 30 to the temporary one).
- `coverage.METRIC_EVIDENCE` rows (state) and promise words for the three reads and `mana_regen_interrupted`
  (`healing power|healing done`, `swim\w*`, `skill`, `mana regenerat\w*`).
- Two `metric_delta` option modules: `ratio_to_metric` (each judged reading divided by a second metric of the same unit,
  read right after it; a missing or zero base leaves the reading missing) and `skill_line` (a skill line given to the
  caster at the start of the before phase).
- Witch Doctor entries: `560280 healing_power`, `561069 swim_speed`, `705911 regen_casting`, `536213 alchemy_bonus`, each
  with the unlearned or uncast before phase as the control.

## Consequences

- New metrics and options only; no default changes. Generated scenarios of classes 19 (with and without `--stack`) and
  23 are byte-identical; class 13 gains four scenarios.
- `compare.DETERMINISTIC_STAT_METRICS` is unchanged: every entry of the new reads states its tolerance.
- Catalog scenario `witch-doctor-harness-state-reads.json` exercises each read without and with its aura.
- Seeded tests in `metric_delta_options/test_ratio_to_metric.py` and `test_skill_line.py`.
