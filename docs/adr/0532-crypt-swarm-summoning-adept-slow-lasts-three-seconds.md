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

- The slow lingers up to 3000 ms after the channel's last hit: an implementation choice of this ADR (the tooltip states
  no slow duration), not a claim; the reads below about the linger are context (mentor ruling). 803530 carries
  SPELL_ATTR5_DO_NOT_DISPLAY_DURATION, so the client shows no timer. Live logs hold no 803530 event over 1325
  casts; the ruling departs from live.
- Regression (class file 501886): the claim, slowed while channeling, is `slow` (0.7 of the dummy's run speed 1200 ms
  into the channel, its own rate without 92123), `slow_applied` (6 applications) and `slow_ends` (back to its own rate
  6550 ms of game time after the cast, ADR 0501). Context only: `slow_held` (slowed at 6270 ms) and `slow_remaining`
  (a readback: 803530's remaining duration 2389 / 2407 ms at 4009 ms, so the last refresh came at 3398 / 3416 ms, each
  800343 bolt flying about 231 ms over 3 yd at 13 yd/s); on that basis the slow ends about 2854 to 3168 ms after the
  last hit.
