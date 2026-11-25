# 0027. Vow of the Valkyr's Fulfillment triggers one auto attack per weapon per ability cast

- Status: accepted
- Confirmed: owner ruling O-23 (2026-11-22): a channel tick counts as its own cast, as decided by D-148.
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

A channel tick is its own cast: each Sunslam tick (805639) and each Radiant Flame tick (807058) fulfils the Vow on its
own (#13027, 90cca54837, from Ascension footage of Sunslam and Radiant Flame; regression scenario 9148). Mentor
decision D-148 (2026-11-22) keeps that rule under O-12, which is about one cast striking with two hands, not about a
channel's ticks. `Origin()` resolves every tick to the channel, so a mark on the resolved cast would let only the first
tick of a channel fulfil.

The last Sunslam tick fulfilled nothing, a fault older than O-12 (since e36bc50aad, 2026-09-10) with the cause ADR 0017
found for Radiant Flame. Sunslam 805629: DurationIndex 35 (4000 ms), Effect[0] aura 227 on the enemy, amplitude
1000 ms, AttributesEx5 0 (no tick at apply), so 4 ticks, the 4th at the channel's end. In that map update the player's
channel finishes and its pointer is dropped before the dummy's aura fires the 4th tick; `Origin()` then returns the
tick, `OnSpellBeforeEffects` skips the copy of `Dawn`, `DawnCast` and 807523 from the channel, and the proc sees no
fulfilment. Measured on pair 20261122-124514 / -124620 (build 066088b360f6, tick guard of D-148 applied): 4 ticks,
3 main-hand and 3 off-hand attacks. At the class head before O-12 the result was 3 per weapon as well; with the mark
on the resolved cast it was 1. Mentor decision D-150 (2026-11-22) sets the conditions of the fix: the tick count from
the DBC, no second Dawn charge, and a regression on both clocks.

## Options

- Keep one 506821 cast per damage event (option a, refused).
- Mark the ability cast once 506821 has been cast for it, as the Vow of Dawn bounce does with script value 803491
  (#9630, later the per-spell guard): one cast per ability.

For the last Sunslam tick:

- Spend Dawn on the late tick, as ADR 0017 does for Radiant Flame. It would spend a second charge per Sunslam, which
  spends its charge at the channel's own cast, and would gate the tick on the Dawn timer at the tick, not at the cast.
- Keep the channel's marks on the player. It adds class state that outlives the channel.
- Carry the channel's marks on its own 805629 aura, which the dummy still owns while the last tick fires.

## Decision

The second option. The 807749 branch casts 506821 only when its guard cast carries no script value 807749, and sets
it. The guard is the one `Fulfill()` already uses: the raw tick spell for 805639 and 807058, otherwise the cast that
`Origin()` resolves. The triggered damage spells 800691 and 802566 resolve to their parent cast, so the second damage
event of one Glorious Execution finds the mark; each channel tick is a new spell and carries no mark.

For the last Sunslam tick, the third option (D-148, D-150). In `OnSpellBeforeEffects`
(`AscensionSunClericAbilities.cpp`), a Sunslam tick 805639 fired by a Sunslam rank (`GetTriggeredByAuraSpellInfo()`,
as ADR 0017 recognises the Radiant Flame tick) finds that rank's aura on its target, cast by the cleric. While the
channel is current, the tick copies `Dawn`, `DawnCast` and 807523 from the channel onto itself and onto that aura; a
tick that finds no channel copies them from the aura. The last tick then carries the cast's marks, and the guard above
lets it fulfil once per weapon. No Dawn charge is spent on a tick.

## Consequences

- Glorious Execution: 1 main-hand and 1 off-hand attack per cast. One-hit abilities are unchanged (1 per weapon).
- Sunslam: 4 ticks give 4 attacks per weapon, whichever comes first in the map update: the channel's end or the
  last tick. Dawn loses one charge per Sunslam, at the cast. Radiant Flame keeps ADR 0017's route for its last tick
  (its per-tick Fulfillment count is not measured by these entries).
- Because the last Sunslam tick now carries Dawn and DawnCast, every active Vow fulfils on it, not only Vow of the
  Valkyr: Vow of Grace 803489, Vow of the Eclipse 807435 and 807547 (twice), and the Vow of Dawn 803491 bounce count,
  with the side effects of `Fulfill()` and the Solar Power suppression (`AscensionSunClericEvents.cpp:163-182`,
  `AscensionSunCleric.cpp:287-303`). This follows D-148 (each tick is its own cast); only the Vow of the Valkyr counts
  are measured here, the other Vows' per-tick counts are not.
- The 805629 aura's script values `Dawn` (807440), `DawnCast` (804584) and 807523 are written and read only by this
  branch; no other code reads script values of 805629, and only Sun Cleric code names 805629 and 805639.
- The key 807749 is a script value of the Spell object only; no other code reads it. No other class reads 807749,
  506821, 506823 or 506824 (`src/`, `modules/`: only the spellbook tables list 807749).
- Regression entries (`sun_cleric.json`, 807749): `fulfillment_main` and `fulfillment_off` (Glorious Execution, gain 1
  each), `gavel_fulfillment_main` and `gavel_fulfillment_off` (Gavel of Light 800611, one hit, gain 1 each), each
  against a control phase without the Vow; `sunslam_fulfillment_main` and `sunslam_fulfillment_off` (Sunslam 805629,
  4 ticks, gain 4 each) with the tick count `sunslam_ticks` as their control, and `sunslam_dawn_charges` (Dawn
  set to 10 charges in each phase, 9 after each channel; a spend on the late tick would read 8); Valkyr weapon set.
  On the simulated clock the channel's end and the 4th tick land in the same map update with the players first, so the
  entries force the late tick by construction; real-clock reference runs cover the other order. After the fix, pair
  20261122-130647 / -130722 (build e6ed4b2b5afd), no flip: 4 main-hand and 4 off-hand attacks from 4 ticks, Dawn 9
  after each channel; real-clock reference 20261122-130811 the same. Scenarios 9148 and 12951 stay green
  (20261122-131020).
