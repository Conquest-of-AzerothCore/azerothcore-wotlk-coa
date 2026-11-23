# 0810. A mixed-mask normalized value hit is judged on its loaded school

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16
- Supersedes in part: [0762](0762-a-script-hit-can-be-a-normalized-weapon-roll-plus-passed-points.md) (the reading of a
  raw school mask 5 strike as physical)

## Context

ADR 0762 judged Purifier's Edge 802434's strikes (803357 main hand, 803517 off hand, raw `SchoolMask` 5, Physical +
Fire) as physical: the off-hand factor 0.5 on the weapon roll and on the passed 277, full armor and no resistance
roll. The off-hand label alerted (about 325 measured against 158 modelled). The diagnosis
(`.agents/plans/witch-hunter/c15/diag-319-off-hand.md`, mentor D-259) traced the engine path; the repository already
recorded the rule in `.agents/docs/systems/ascension-spell-parity.md:180-183` ("Purifier helpers with raw mask 5
therefore execute the Fire weapon path").

- `SpellMgr.cpp:3936-3941` (`LoadSpellCustomAttr`): a mask that mixes `SPELL_SCHOOL_MASK_NORMAL` with a magic school
  loses NORMAL and gains `SPELL_ATTR0_CU_SCHOOLMASK_NORMAL_WITH_MAGIC`. The loaded mask of both strikes is 4 (Fire).
- `SpellEffects.cpp:4688`: `isPhysical = m_spellSchoolMask & SPELL_SCHOOL_MASK_NORMAL` is false, so the passed points
  are not multiplied by the hand's TOTAL_PCT (`SpellEffects.cpp:4689-4706`), and
  `CalculateDamage(m_attackType, normalized, isPhysical)` (`SpellEffects.cpp:4719`) rolls the weapon with
  `totalPct = 1.0` (`StatSystem.cpp:732`), so the off-hand 0.5 (`Unit.cpp:13521-13523`) is not applied.
- `Unit.cpp:2422-2426`: no armor step for a mask without NORMAL. `Unit.cpp:2672`: the resistance roll runs.
  `Unit.cpp:2729-2735`: for `SPELL_ATTR0_CU_SCHOOLMASK_NORMAL_WITH_MAGIC`, the resisted amount is capped at the armor
  reduction `damage - CalcArmorReducedDamage(...)`, whose kept part is `ceil(damage x (1 - reduction))`
  (`Unit.cpp:2579`). Each hit loses min(resist roll, armor reduction).

## Options

- Use the loaded mask for every mixed mask automatically. Rejected: the part would change silently for any class file
  that already judged a mixed mask (none outside the Witch Hunter today), and the brief asks for an opt-in.
- An opt-in `effective_school: true` on a `normalized_value` script hit, and a refusal of a mixed mask without it.
  Chosen.
- A zero-armor fixture, where the cap removes the resistance: kept as a seeded check of the model, not as the
  scenario, since the counted pair runs on the reference dummy (armor 528).

## Decision

`script_hit` takes `effective_school: true` only with `normalized_value: true`. The model reads the loaded mask (the
raw mask without the physical bit when it also holds a magic bit). With it, neither hand takes the off-hand factor:
the weapon roll plus attack power / 14 x the normalized speed, truncated, plus the full passed points; the school
modifiers are those of the loaded mask; each value of the distribution loses, for each resistance step of the loaded
school (the existing partial resistance shares), min(value x step / 10 truncated, value - ceil(value x (1 - armor
reduction))). An `unresisted` entry takes no mitigation. A mixed raw mask without `effective_school` is unmodelled, as
is `effective_school` on a mask that does not mix; a non-mixed, non-physical off-hand strike stays unmodelled
(ADR 0762).

## Consequences

- Opt-in: Templar 19 and Necromancer 23 have no `normalized_value` entry and regenerate byte-identical.
- Seeded tests (`test_hits.py`, `NormalizedValueTest`): both hands' tooltip mean is the full roll plus 277; the
  reference mean equals the capped-resistance sum computed from the resistance shares; with armor 0 the mean is the
  unmitigated roll and a hit there passes; a physical mask (patched to 1) keeps the off-hand factor and armor. Mutants
  that must alert: the halved physical off-hand value and a main-hand hit without the 277.
- Witch Hunter: 802434 `main_hand` and `off_hand` carry `effective_school`; the reference model is 324.0 per
  non-critical hit for each hand with the 2027 weapon. The diagnostic runs measured 322.9 to 333.4.
- The other counted Witch Hunter hit labels were listed against the server DBC masks: none of them judges a mixed-mask
  spell with the physical model (report `.agents/plans/c15-tool5/report.md`).
