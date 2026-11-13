# 0045. The Dominion of Frost gate is read with two minions

- Status: accepted
- Date: 2026-11-13

## Context

Claim 105.0, Dominion of Frost 537208 "Can only occur once per sec.": a minion crit cuts Unholy Frenzy 805029 by
3000 ms when `Chance(player, 537208, 1, 1000)` passes (AscensionNecromancerEvents.cpp:181-182). One Ghoul crits every
2000 ms, so the 1000 ms gate never binds. Forcing crits on two minions of one entry needs a harness change (the
owned-entry `set_aura` picks one creature); the mentor asked for the cheap design first: a second melee entry.

## Options

- Harness C++: `set_aura` on every owned creature of an entry (beyond the cycle timebox).
- Two minions of distinct entries, each forced to crit by its own owned-entry `set_aura`.

## Decision

Kind `minion_crit_gate` (kinds/minion_crit_gate.py) with a Ghoul 50073 and a Lesser Skeletal Warrior 50065 (1 Life
Force each, both 2000 ms swings, started together by the caster's attack). Accepted cuts (cooldown removed beyond
elapsed time over 3000 ms) per counted crit must lie in 0.4 to 0.75: about 0.5 when the second crit of each pair falls
inside the gate, 1.0 with no gate.

## Consequences

- Pilot 20261113-174302: 24000 ms removed beyond the elapsed time (8 cuts) for 15 crits, 0.533.
- The read brackets the gate between the two minions' swing offset and one swing period (2000 ms); it does not pin
  1000 ms. A gate of 3 s or more, or none, alerts.
