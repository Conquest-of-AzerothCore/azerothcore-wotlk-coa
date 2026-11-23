# 0012. Owner rulings O-16, O-18 and O-19

- Status: accepted (owner rulings O-16, O-18, O-19, 2026-11-23)
- Date: 2026-11-23

## Context

Three Felsworn tooltip questions went to the owner.

- O-16, Tyrant's Gaze 805240: "intimidating them and causing them to combust".
- O-18, Consumed By Fel 300485: "Increases the tick rate of Immolation Aura by $s2%." Effect 1 is aura 108
  `SPELLMOD_ACTIVATION_TIME` at -25 on Immolation Aura 572617, whose amplitude is 3000 ms.
- O-19, Felstrike 802678: the client shows 54 over six ticks (6 x 9, base points only, ADR 0006) while the server
  applies 34 per tick at level 60 (BasePoints 8 + 1, RealPointsPerLevel 0.5, BaseLevel 10).

## Decision

- O-16: "intimidating them" is flavour text, not a claim. The damage and nearby-enemies claims of the clause keep
  their labels.
- O-18: the data governs. The stock engine applies the modifier to the amplitude, 3000 x 0.75 = 2250 ms. The Sun
  Cleric ruling O-24 (ADR sun-cleric/0031, period P x 100 / (100 + X)) is not extended to this class.
- O-19: the server keeps 34 per tick. The displayed text is to be corrected; a clause value is counted on the server
  formula (`SpellEffectInfo::CalcValue` from the DBC fields) with the reason "displayed text to be corrected (O-19)".
  Entry `802678 tick_value` expects 34.

## Consequences

- The 300485 entry and its expectation are carried by the branch that holds the entry; this ADR records the ruling
  only.
- ADR 0006 keeps its reading of the client text; its "open owner question" for Felstrike is answered here.
