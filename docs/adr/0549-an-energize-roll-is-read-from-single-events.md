# 0549. An energize roll is read from single events

- Status: accepted
- Date: 2026-11-13

## Context

Soulfreeze 801724's "Each tick generates $/10;800344s2 Runic Power" (ledger 398.0) is delivered by 800344, which each
801728 tick triggers: Effect[1] ENERGIZE, BasePoints 29 + DieSides 51, a roll of 30 to 80 internal units. The
controller asked for a pooled proof of that roll (band on the minimum and the maximum, at least 384 ticks, so that a
uniform roll misses one end with probability below about 1e-3), and for a read of single energize events if none
existed. The harness reads only cumulative energize totals and counts.

## Decision

- A behaviour kind `energize_range` casts a spell repeatedly and reads the cumulative energize total and count of the
  energize spell every 250 ms; an interval whose count rose by exactly one gives one event's amount. No harness C++
  change: the single-event amount is the difference of two cumulative reads.
- The judge needs `minimum_events` single events, every amount inside `low`..`high`, and both ends seen: `ok`; an
  amount outside or an end not reached in enough events: `alert`; too few events: `unmeasured`.
- Soulfreeze: 160 casts of 801724 (140 gave 354 and 372 single events) at an Ice-Locked dummy (The End Is Near 680486 for the cost, 572023 not learned so the
  ticks do not re-proc), 384 single events needed.
- Other entries generate the same scenarios (Templar `generate --class 19` and `--stack` byte-identical).

## Consequences

- The token $/10;800344s2 shows the base, 3.0; the roll is the server's (3.0 to 8.0 shown). The claim's status follows
  the counted pair; the text alignment is not this ADR's subject.
- Tests: `EnergizeRangeTests` (test_behaviours.py).
