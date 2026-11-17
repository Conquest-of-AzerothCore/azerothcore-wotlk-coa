# 0607. A minion's school spell crit is read through the engine's roll chance

- Status: accepted
- Date: 2026-11-13

## Context

Claim 9.1, Curse of the Lich 300240 "and your summons by $s2%": Effect[2] (190,
SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS) puts aura 71 SPELL_AURA_MOD_SPELL_CRIT_CHANCE_SCHOOL, Frost +3, on the
owner's summons. `owned_creature_spell_crit_chance` reads `m_baseSpellCritChance`, which Scale() copies from the
caster's Frost crit (AscensionNecromancerSummons.cpp:318-320); stock code adds
a creature's aura 71 only when the crit is rolled (Unit::SpellDoneCritChance,
Unit.cpp:10264-10267). The base read cannot see the minion's own grant.

## Options

- Sum `m_baseSpellCritChance` and `GetTotalAuraModifierByMiscMask(SPELL_AURA_MOD_SPELL_CRIT_CHANCE_SCHOOL)` in the
  harness: a second copy of the engine formula that can drift from it.
- Call the engine's own `Unit::SpellDoneCritChance` with a magic probe spell and no victim.

## Decision

Metric `owned_creature_school_spell_crit_chance` (CoAGameplayTest.cpp, beside `owned_creature_spell_crit_chance`):
fields `entry`, `spell` (required, `DmgClass` MAGIC, else the step is refused) and `school_mask` (default Frost). It
returns `SpellDoneCritChance(nullptr, info, mask, BASE_ATTACK, true)`. The method is const; with a null `Spell*`
`ApplySpellMod` changes only the local value (`ApplyModToSpell` returns at once, Player.cpp:10880-10883), so no
charge is used and no state is left. It is a STATE read with the crit promise words (coverage.py).

## Consequences

- The owner's crit spell modifiers on the probe spell add a constant offset to both phases; entries judge gains.
- The skipEffectCheck flag is true, so any magic spell of the school serves as the probe (Lichfrost 501978 for
  Frost).
- Templar has no entry with this metric; Templar `generate --class 19` and `--stack` are byte-identical to
  019887b267.
