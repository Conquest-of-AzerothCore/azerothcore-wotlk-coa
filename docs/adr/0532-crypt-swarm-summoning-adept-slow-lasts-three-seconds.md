# 0532. Crypt Swarm's Summoning Adept slow lasts three seconds

- Status: accepted
- Date: 2026-11-13

## Context

Crypt Swarm 501886 casts 803530 at its target on each own 800343 hit while Summoning Adept 92123 is known
(AscensionNecromancerEvents.cpp). 803530 has DurationIndex 0, so the -30% speed aura was removed at once and the target
never slowed. The owner ruled (Q-b3b-1, option a) that the slow is meant. Fix note FN-own-9, approved by the mentor
(09:3x) with DurationIndex 27 (3000 ms, Crypt Swarm 501886's own DurationIndex, the tooltip's $d).

## Decision

- Necromancer contract, family-29 section: 803530 gets SpellDuration row 27 (3000 ms). Each of the six hits (500 ms
  apart) refreshes it.

## Consequences

- The slow lingers up to 3000 ms after the channel's last hit. 803530 carries SPELL_ATTR5_DO_NOT_DISPLAY_DURATION, so
  the client shows no timer. Live logs hold no 803530 event over 1325 casts; the ruling departs from live.
- Regression (class file 501886): `slow` (0.7 of the dummy's run speed 1200 ms into the channel, its own rate without
  92123), `slow_applied` (6 applications), and a held / ends pair stamped in game time (ADR 0501): `slow_held` slowed
  5850 ms after the cast (window 5850-5900 ms), `slow_ends` back to its own rate at 6130-6160 ms. With the last hit at
  3000 ms the slow lasts between 2850 and 3160 ms after it.
