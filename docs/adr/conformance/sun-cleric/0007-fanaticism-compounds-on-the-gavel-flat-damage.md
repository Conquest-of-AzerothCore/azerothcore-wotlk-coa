# 0007. Fanaticism compounds its effectiveness on the Gavel flat damage

- Status: superseded by [0029](0029-gavel-effectiveness-talents-apply-to-the-whole-hit.md) (owner ruling O-18): the Gavels no longer keep the stock engine order
- Date: 2026-11-22

## Context

Fanaticism 805628, Spell.dbc text: "Increases the effectiveness of Gavels and Horusath Blast and reduces their mana cost
by $s2%." The tooltip states no effectiveness figure. Effect[0] is aura 108 ADD_PCT_MODIFIER, MiscValue 8
(SPELLMOD_ALL_EFFECTS), BasePoints 19 (+20%); Effect[1] is the mana cost, -20%; both on class mask word 1 = 96.

Measured on the counted pair 20261122-004435 / -004630 (build 8de1aad63b12, level 60 dummy with armor 528, passive
learned against not learned, non-critical hits):

| Spell | Flat part B (DBC mean) | Bonus on the mean hit |
|---|---|---|
| Gavel of Wrath 800617 | 50 (BasePoints 44, DieSides 11) | +27.39% and +27.10% |
| Gavel of Grace 800614 | 24.5 (BasePoints 22, DieSides 4) | +23.76% and +23.84% |
| Gavel of Light 800611 | 12 | +21.74% and +21.60% |
| Horusath Blast 500154 | none | +19.33% (99% interval +18.42% to +20.24%) |

The Gavels read above +20%. `Spell::EffectWeaponDmg` (`SpellEffects.cpp:4676`, `:4681`): `CalculateSpellDamage` applies
SPELLMOD_ALL_EFFECTS to the flat effect value (NORMALIZED_WEAPON_DMG) and to the weapon-percent effect (100% becomes
120%), and the loop at `:4729-4741` adds the flat value to the weapon damage before it applies the percent, in DBC order.
The treatment hit is 1.2 x (W + 1.2 x B), the control hit is W + B, with W the weapon part and B the flat part.

## Options

- (a) Accept the stock engine order. The tooltip gives no figure; every multi-effect spell with this modifier takes the
  same path.
- (b) Limit the modifier to the damage effect, through a class contract or the per-spell flag
  `SpellInfo::AscensionFlatAfterWeaponPercent` of ADR 0010. That ADR requires Ascension evidence per class before the
  flag is used elsewhere, and there is none for the Gavels.

## Decision

Option (a), mentor D-54. The expectation is the engine arithmetic, with the compounding in words: Fanaticism raises the
flat part of a Gavel twice, once inside the +20% effect value and once through the +20% weapon percent that scales the
sum, and the weapon part once. The bonus is 20% + 24% x B / (W + B).

The expected values come from W, B and the armor read, never from the measured bonus. B is the flat mean from the DBC.
Armor reduces the whole physical hit (the dummy's armor 528, read by the `dummy_armor` entry: r = x / (1 + x) with
x = 528 / (85 x 60 + 400), r = 8.76%), so W + B is the control mean hit divided by (1 - r). The control mean is a
baseline reading of the control arm of the pair above (140.827, 118.173 and 106.63), not a bonus.

| Spell | W + B | Expected bonus |
|---|---|---|
| Gavel of Wrath | 154.35 | +27.77% |
| Gavel of Grace | 129.52 | +24.54% |
| Gavel of Light | 116.87 | +22.46% |
| Horusath Blast | not needed | +20% |

Band for Horusath Blast: one SCHOOL_DAMAGE effect and no flat term, so the arithmetic gives exactly +20%. The claim is
judged in the G-19 band, the larger of 5% of the stated bonus and 2 points: 18% to 22%. The measured +19.33% lies
inside it, and its 99% interval (+18.42% to +20.24%) holds +20%, so it does not reject the stated value.

## Consequences

- The class file's `effect_gavel`, `effect_gavel_grace` and `effect_gavel_light` entries carry the three expected
  ratios above in place of 1.2; the Horusath Blast entry keeps 1.2. Their `expected_source` states the arithmetic.
- Computing W + B from the control arm of the same pair at judge time needs a shared-tool change that was not made
  here: the control means are fixed readings of the pair above. A change of the reference weapon or attack power moves
  them; the band absorbs a small move only.
- No server change, no client data change.
