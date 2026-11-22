# 0027. Vow of the Valkyr's Fulfillment triggers one auto attack per weapon per ability cast

- Status: accepted
- Date: 2026-11-22

## Context

Vow of the Valkyr 807749, Spell.dbc text: "Fulfillment: Melee ability damage triggers an auto attack with each weapon."
Under Dawn, the class code (`AscensionSunClericEvents.cpp`, commit e36bc50aad, no rationale recorded) cast 506821 for
every damage event of a direct melee ability. 506821's Effect[0] and Effect[1] trigger 506824 (main hand) and 506823
(off hand). Glorious Execution 800626 strikes with both weapons through 800691 and 802566, so one cast has two damage
events. Measured on pair 20261121-021237 / -021438 (build 4dc152e975e5): 2 main-hand and 2 off-hand attacks per
Glorious Execution, 4 in all; a one-hit ability gave 1 per weapon.

The text can be read per damage event or per cast, and no log, snapshot or changelog settles it (owner question
Q-sc-1). The owner ruled O-12 (2026-11-22, option b): one auto attack per weapon per ability cast. Glorious Execution
then triggers 2, not 4.

## Options

- Keep one 506821 cast per damage event (option a, refused).
- Mark the ability cast once 506821 has been cast for it, as the Vow of Dawn bounce does with script value 803491
  (#9630, later the per-spell guard): one cast per ability.

## Decision

The second option. The 807749 branch casts 506821 only when the cast that `Origin()` resolves carries no script value
807749, and sets it. The triggered damage spells 800691 and 802566 resolve to their parent cast, so the second damage
event of one Glorious Execution finds the mark.

## Consequences

- Glorious Execution: 1 main-hand and 1 off-hand attack per cast. One-hit abilities are unchanged (1 per weapon).
- The key 807749 is a script value of the Spell object only; no other code reads it. No other class reads 807749,
  506821, 506823 or 506824 (`src/`, `modules/`: only the spellbook tables list 807749).
- Regression entries (`sun_cleric.json`, 807749): `fulfillment_main` and `fulfillment_off` (Glorious Execution, gain 1
  each), `gavel_fulfillment_main` and `gavel_fulfillment_off` (Gavel of Light 800611, one hit, gain 1 each), each
  against a control phase without the Vow; Valkyr weapon set.
