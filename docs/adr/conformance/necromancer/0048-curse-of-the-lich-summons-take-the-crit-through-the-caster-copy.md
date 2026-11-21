# 0048. Curse of the Lich's summons take the Frost crit through the caster copy

- Status: accepted
- Date: 2026-11-13

## Context

Claim 9.1, Curse of the Lich 300240 "increases the Frost critical strike chance of you and your summons by $s2%"
($s2 = 3). Effect[1] gives the caster aura 71 Frost +3; Effect[2] (190, SPELL_EFFECT_ASCENSION_APPLY_AURA_TO_SUMMONS)
gives the summons the same aura. Scale() (AscensionNecromancerSummons.cpp:318-320) sets a minion's
m_baseSpellCritChance from the caster's whole Frost spell crit, which includes Effect[1]. Necromancer ADR 0047's
counted pair read the Ghoul at +6. The mentor confirmed a double grant and set the rule: if the copy is general, remove
Effect[2]; if it covers only specific sources, exclude 300240 from the copy.

## Options

- Remove Effect[2]'s summon grant through a Necromancer contract; Scale() passes the caster's +3.
- Keep Effect[2] and leave 300240's Effect[1] out of the copy.

## Decision

The copy is general. In pilot 20261113-181949, another caster Frost crit source (Enigma Crit Bonus 26127, passive aura
71 on Arcane, Fire and Frost, +3, learned in place of 300240) raised the Ghoul by +3 in both the school read and the
base copy read. So the first option applies: `ApplyContracts` sets 300240 Effect[2] to 0. Effect[0] (Rime range) and
Effect[1] stay.

## Consequences

- The summons gain +3 once, through the copy; the caster's +3 does not change.
- The 0047 layout with Effect[1] at 0 now leaves the summon nothing: `summon_school_crit_alone` expects +0 and
  `summon_talent_aura` expects no 300240 aura on the Ghoul. If either reads a gain again, a separate summon grant has
  returned.
- Two arms with the 26127 gate, `summon_other_source` and `summon_other_source_base` (+3 each), cover the general copy.
- Every live Necromancer summon goes through Scale(): each family-29 summon effect (28) in the server Spell.dbc, and
  each `NecromancerSummons` row (AscensionNecromancerData.h:94), names a creature whose `creature_template` has
  ScriptName `npc_ascension_necromancer` and type 6 (Undead), or a creature that does not exist (5030301, 50077,
  50130, 55065, 55066, 3333313); that AI calls Scale() on summon (AscensionNecromancerSummons.cpp:515) and every
  second in event 1 (:763, rescheduled at :817).
