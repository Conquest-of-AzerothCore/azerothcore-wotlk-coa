# 0035. Fervor of the Sun raises Sunslam's damage by a percent per stack

- Status: accepted (mentor D-219, confirmed defect under the tooltip, 2026-11-22)
- Date: 2026-11-22

## Context

Fervor of the Sun 680622: "Fulfilling a Vow now increases the damage of your Sunslam by $680623s1% for $680623d,
stacking $680623u times." The proc 680623 shows "Damage dealt by your Sunslam is increased by ${$w1}%." Its Effect[0]
is aura 107 (ADD_FLAT_MODIFIER), MiscValue 3 (SPELLMOD_EFFECT1), BasePoints 9 + 1 = 10, class mask word 1 = 2097152,
StackAmount 5 (`/srv/coa/server-data/dbc`, Spell.dbc). In SpellFamilyName 33 only the Sunslam tick 805639 and the
weapon part 807447 carry that bit (SpellFamilyFlags[1] & 0x200000, DBC scan).

The tick's value is 100 (807973 Effect[0] aura 227, BasePoints 99 + 1) plus 0.159426 x attack power, added by
`sun_cleric_scaling::ModifySpellEffectBaseValue` (`AscensionSunClericContracts.cpp`, row 805639 of
`SunClericCoefficients`). `SpellEffectInfo::CalcValue` then applies the SPELLMOD_EFFECT1 modifiers through
`Unit::ApplyEffectModifiers` (`SpellInfo.cpp:523-531`), so the flat +10 lands on the full value: pair
20261122-212938 / 20261122-213016 (build e3912f63d5c9) read the tick 111 -> 121 (1.0901) at attack power 70 and
1.0058 / 0.9957 at 10000, against the tooltip's 1.10.

## Options

1. Make 680623 Effect[0] aura 108 (ADD_PCT_MODIFIER) in the class contracts. `Player::ApplySpellMod` applies the
   percent after the attack power term and adds the percent modifiers of SPELLMOD_EFFECT1, and the aura amount is
   10 x stacks (`AuraEffect::CalculateAmount`), so the tick reads 1 + 0.10 x stacks.
2. Multiply 805639's value by the Fervor stacks in `ModifySpellEffectBaseValue`. Rejected: the flat +10 of the DBC
   aura would still apply on top, and a second rule would have to cancel it.
3. Change `SpellInfoCorrections.cpp`. Rejected: a shared engine file.

## Decision

Option 1. `AscensionSunCleric::ApplyContracts` sets 680623 Effect[0] ApplyAuraName to SPELL_AURA_ADD_PCT_MODIFIER
(`AscensionSunClericContracts.cpp`). BasePoints, MiscValue and class mask keep their DBC values.

## Consequences

- With one stack Sunslam's tick deals 10% more, with five stacks 50% more, at every attack power.
- Reach: 680623 is cast only by `AscensionSunCleric::Fulfill` when the player has 680622
  (`AscensionSunCleric.cpp:295-296`); its mask reaches 805639 and 807447 only, both Sun Cleric spells. Atone, Or Else
  680619 raises 680623's stack cap through SPELLMOD_MAX_AURA_STACKS on 680623 itself, not through this effect. No
  other class's spell, no shared engine path, no SQL and no client text change; the client tooltip already states a
  percent.
- The weapon part 807447 is not observed to land (807973 Effect[1] aura 231 with ProcFlags 0, no source reference,
  0 events in 186 logs): recorded in the ledger for the owner, unchanged here.

## Verification

See the class conformance report of this fix: the counted pair at level 60 on the fix build, the tick_ratio entries
at attack power 10000 and 70 with one stack (expected 1.10) and five stacks (expected 1.50), each against the control
without Fervor, and the Fervor stack and duration rows and the Sunslam stun and aura rows unchanged.
