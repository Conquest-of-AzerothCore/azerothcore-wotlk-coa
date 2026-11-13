# 0383. The Skeletal Rogue's Command strikes and strike bursts

- Status: accepted
- Date: 2026-11-13

## Context

Raise: Skeletal Rogue 500969: "Command: Leaps to your target and strikes it $805938s1 times. Always strikes 5 times on
enemies below 35% health." 805938 Effect[0] is SPELL_EFFECT_ADD_EXTRA_ATTACKS with BasePoints 1 and DieSides 4, the
engine's encoding of 2 to 5 (`SpellEffectInfo::CalcValue` rolls BasePoints + 1..DieSides). The Rogue's event 6
(AscensionNecromancerSummons.cpp:846-853) struck exactly 2 times above 35% (pairs 20261113-003823 / -003900: 6 hits for
two Rogues, 2 strikes and one auto attack each). The mentor approved using the effect value (Q-b2b-2): the range is in
the data, not only in the text.

## Considered options

1. A hand-written random 2 to 5. Rejected: the data carries the die.
2. Roll 805938 Effect[0] through `CalcValue` for each Command. Chosen.

## Decision

- Above 35% health the Rogue strikes `Amount(805938, 0, me)` times (CalcValue), and 5 times below.
- The conformance kind `strike_bursts` reads a minion's hits just before and just after its scripted strike tick, per
  Command, with a stance cycle (Pacify, then another stance) that stops the minion between Commands, a control
  Command with no minion raised, and arms of falling target health. Its judge (a `behaviour_metric_delta` verdict)
  requires every count inside the arm's range and both ends seen.

## Consequences

- 40 Commands at 37% must show only 2 to 5 and both 2 and 5 (a correct server misses either with probability
  0.75^40, about 1e-5); 10 Commands at 33% must show 5 each; the target stands 6 yd away, so a strike at 500 ms needs
  the leap.
