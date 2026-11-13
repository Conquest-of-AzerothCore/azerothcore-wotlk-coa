# 0485. A rolled minion aura's expiry is read in game time

- Status: accepted
- Date: 2026-11-13

## Context

Frenzied Ghoul 707014 ("for $d", 10 s) and Plague Horde 807653 ("for $807653d", 5 s) are put on a minion by its own
roll (Ghoul Mastery 503740, Plague Horde 802986). With the roll forced (ADR 0482) every hit refreshes the aura, so its
expiry could not be bracketed. A first design (the mentor's: stop the roll after the first proc, then poll the aura
every 100 ms) read 9.0-9.3 s and 4.5-4.7 s, both about 8% short. The cause is the harness clock, not the server: in
those scenarios the game time ran 10 to 17 ms past the nominal `ms` of every wait step (164 wait steps), so a duration
counted in nominal waits through many short waits comes out short. The mentor asked for the second design (G-25): stamps
of the last proc and of the reads in game time.

## Decision

- Read-only harness metrics (G-39): `game_time_ms` (the server's game time, `GameNowMs()`) and
  `owned_creature_spell_cast_count` (the casts of a spell by an owned creature: the harness cast counter, keyed per
  map instance since #12154).
- A behaviour kind `aura_expiry`: forced roll while one minion attacks, then a -100% chance mutant so
  no roll applies the aura again; reads every `poll_ms` of game time, the minions carrying the aura and the marker
  casts. The verdict brackets the duration between the last marker cast and the first read without the aura, both in
  game time, and judges it against the stated value +- 5% (G-19). A cast after the switch alerts; no cast before it is
  unmeasured; the forcing mutant must be removed at the end.
- Every duration claim read through many short waits must be judged on game-time stamps, not on the sum of the nominal
  waits. Entries that read a duration with one or two long waits (the held / ends pairs) carry the overhead of those few
  steps only.

## Consequences

- Pilot x1 (build after this change): Frenzied Ghoul 9865-10089 ms against 10000, Plague Horde 4937-5161 ms against
  5000, both ok. The no-talent controls are the forced entries' absent reads (frenzied_display, horde_no_talent).
- Tests: `AuraExpiryTests` (test_behaviours.py). Templar `generate --class 19` and `--stack` byte-identical.
