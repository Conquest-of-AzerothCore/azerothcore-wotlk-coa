# 0001. Ghoul Frenzy's heal scales with Intellect and spell power

- Status: accepted
- Date: 2026-11-13

## Context

Raise: Ghoul 500971 reads "Its auto attacks restore ${$707000m1+$707000ppl1+(($INT*0.504)+($SP*0.504))*0.07} health
to you." A Ghoul's melee hit casts Ghoul Frenzy 707000 on its owner (AscensionNecromancerEvents.cpp:101-102). The
Necromancer adds the stated Intellect and spell power terms through `NecromancerCoefficients`
(AscensionNecromancerData.h), applied in necromancer_scaling::ModifySpellEffectBaseValue, but 707000 had no row, so
the heal had no stat term (21 before the Ghoul's -30% healing done, 14 measured, against 25 stated). The live logs show
Ghoul Frenzy heals of 44 to 62, above what the base term alone gives at level 60. The mentor approved the fix
(G-37, fix note FN-1 part 1). No other class casts 707000: only 805290's Effect[0] names it, and only the Necromancer's
event script casts it.

## Considered options

1. Leave the heal without a stat term. Rejected: the tooltip states the term and the logs exceed the base value.
2. Add a row with the stated coefficients. Chosen.

## Decision

- Add `{ 707000, 0, 0.03528, 0.03528, 0, 32, true }` to `NecromancerCoefficients`: 0.504 x 0.07 of the owner's spell
  power (healing, Shadow) and of the owner's Intellect, added to 707000 Effect[0]. The contracts set its
  `BonusMultiplier` to 0 for every listed row, so the stock coefficient does not add again.
- The -30% healing done of Ghoul Passive Healing 805290 Effect[1] is unchanged; it is owner question Q-a1-6.

## Consequences

- At the reference character (117 Intellect, no spell power) the heal reads int(25.13) = 25 before and 17 after the
  Ghoul's -30% (14 before this change); with +Intellect it rises (20 measured in the regression arm).
- Regression: the Raise: Ghoul `auto_attack_heal_modelled` and `auto_attack_heal_intellect` entries (two stat levels,
  a control arm without a Ghoul).
