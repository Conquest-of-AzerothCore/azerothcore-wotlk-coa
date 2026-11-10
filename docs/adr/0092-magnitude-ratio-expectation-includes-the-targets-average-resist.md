# 0092. The `magnitude_ratio` expectation includes the target's average resist for a magic-school copy

- Status: accepted
- Date: 2026-11-10

## Context

ADR 0067 left Retribution 707391 ("Melee damage dealt now has a $h% chance to strike 2 additional times for $s1% of
the damage dealt as Holy Damage", `$s1` = 30) as an unexplained `alert`: the per-event ratio of the Holy copy
Retribution 525028 to the main-hand swing measured about 0.263 against 0.3. Round 10 measured 0.2664 on both runs.
`docs/trigger-entries.md` ruled out dummy resistance because the dummy's measured Holy resistance is 0.

That reading is the creature's authored resistance. Monster linear magic resistance
(`docs/coa/monster-linear-resistance.md`, `CoA.MonsterResistance.*`, on by default) adds `level x PerLevel` to every
magic school, Holy included, at combat time in `Unit::GetEffectiveResistChance`, and leaves the displayed
resistance unchanged. A level-60 dummy therefore resists 12% of each Holy hit on average (partial resist 0/10/20/30%
at 20/45/30/5%), which gives 0.3 x 0.88 = 0.264. The copy keeps the resist roll: `TemplarCopies` in
`AscensionTemplarContracts.cpp` sets `SPELL_ATTR0_CU_IGNORE_ARMOR`, `SPELL_ATTR3_IGNORE_CASTER_MODIFIERS` and
`SPELL_ATTR4_IGNORE_DAMAGE_TAKEN_MODIFIERS`, but not `AscensionIgnoreAbsorbAndResistance`, and the documented live
behaviour is that creatures partially resist Holy damage. The tooltip's 30% is the amount of Holy damage struck,
before the target's resistance, as every other Holy amount in the hit checks (`hits.py`, `mitigation.py`) is read.

The check compared the post-resist copy with the bare tooltip fraction, so it reported the documented resistance as a
deviation. Deliverance 801456 (Physical, `CU_IGNORE_ARMOR`) and Uther's Legacy 707302 (a self-heal) are unaffected.

## Considered options

1. Fight a dummy that does not resist (level 1, or penetration on the caster). Rejected: it changes the fight for
   every other trigger of the class file and hides the resistance the server applies to real targets.
2. Mark the clause `uncertain expectation`. Rejected: the resistance model, its live evidence and the copy's
   attributes are documented; nothing in them is in doubt.
3. Measure the dummy's view level and authored resistance in the magnitude scenario and multiply the tooltip fraction
   by `expected_mitigation(...).mean`, the same model the hit checks use. Chosen.

## Decision

- `magnitude_ratio_scenario` reads the observed spell's `SchoolMask` from the DBC. For a `spell_damage_total` copy
  struck at the dummy in a magic school without the Physical bit, it adds `target_steps` (armor, `view_level`,
  `resistance` per magic school) and records `resisted_school_mask`, `caster_level` and `target_measurements` in the
  model.
- `judge_trigger_magnitude` multiplies `expected_ratio` by the observe-count-weighted mean of each usable part's
  kept fraction, and sets the `max(0.01, 5%)` band around that product. A part with a resisted school but no target
  readings counts as a part without measurements (an `alert` when no part is usable). A model without
  `resisted_school_mask` keeps the bare tooltip fraction.
- The explanation names the tooltip fraction and the kept fraction.

## Consequences

- Retribution's round 10 measurement 0.2664 falls inside the new band around 0.264 (0.2508-0.2772); a copy dealing
  the bare 30% against a level-60 dummy would alert. The round 10 scenarios carry no target readings, so the next
  conformance run regenerates them before the verdict changes.
- The scenario `templar-retribution-holy-strike-resist` pins the server behaviour: the copy is 30% of the swing,
  0.295 after integer truncation, against a level-1 dummy (0.2% average resist) and 26.4% against a level-60 dummy.
- ADR 0067's open finding is closed. No server change.
