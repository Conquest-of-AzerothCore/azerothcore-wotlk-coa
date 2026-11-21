# 0052. The Underking random pick is attributed per cycle

- Status: accepted
- Date: 2026-11-13

## Context

Claim 172.1, Underking 704701 "the cooldown of ... Animate ... is reduced by $/1000;302517s1 sec at random". At 10
Underking stacks the server cuts `animates[urand(0, n - 1)]` among the known 805032, 805044 and 805048 by 15000 ms
(AscensionNecromancerAbilities.cpp:301-314). Reduce is a no-op on a spell without a cooldown entry, so a cut is
visible only on a primed Animate. 172.0 proves the cut with one Animate known; no kind attributed a cut to one of
several. Design: review/c7-91-172-designs.md, section 172.1 (mentor-approved).

## Decision

Kind `cooldown_pick_share` (kinds/cooldown_pick_share.py, no C++). Each cycle resets and casts every Animate of the pool
(mana set to the fixture maximum 2848), gives ten Command: Undead 504868, and reads `cooldown_ms` of the pool before and
300 ms after the tenth. The median drop is the elapsed time; a drop of 15000 +- 100 ms more is the pick. One control
cycle per part runs before the talent is learned. Three identical parts of ten cycles are pooled (`parts`): every cycle
must cut exactly one cooldown, every Animate must be picked, and each count must lie in the two-sided 99.9% binomial
band of a uniform pick (2..19 of 30).

## Consequences

- A fixed pick fails with P(pass) 0; a uniform pick fails "every Animate picked" with P <= 3 x (2/3)^30 = 1.6e-5.
- About 38 s of game time per cycle, 7 minutes per part.
