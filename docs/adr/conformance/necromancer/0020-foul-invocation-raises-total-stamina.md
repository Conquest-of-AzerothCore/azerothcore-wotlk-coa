# 0020. Foul Invocation raises total Stamina

- Status: accepted
- Date: 2026-11-13

## Context

Foul Invocation 804371: "increasing your maximum Stamina by $s2%". Spell.dbc 804371 Effect[1] is aura 80
SPELL_AURA_MOD_PERCENT_STAT (MiscValue 2 Stamina, 40%), which the stock handler applies to base Stamina only. The
owner ruled (Q-b1-3, option (b)) total Stamina; the mentor approved fix note FN-own-8.

## Decision

- The 804371 contract block turns Effect[1] into aura 137 SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE; MiscValue 2 stays.

## Consequences

- Regression (class file): `Foul Invocation` stat_gain (0.4 x the Stamina read, at the reference Stamina and with
  Stamina 48101 +63; the reading before each cast is the control).
- Aura 137 multiplies with other TOTAL_STAT_PERCENTAGE auras instead of adding to the base percent. Minion Stamina
  follows the player's (not measured).
