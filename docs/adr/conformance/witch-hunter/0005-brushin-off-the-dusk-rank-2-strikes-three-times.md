# 0005. Brushin' Off The Dusk rank 2 strikes three times

- Status: accepted
- Date: 2026-11-15

## Context

Brushin' Off The Dusk rank 2 (681488) reads "Your off-hand auto attacks now have a $h% chance to strike 3 additional
times"; rank 1 (681329) reads "strike 2 additional times". Each rank's Effect[0] triggers its own extra-attack spell:
681392 (rank 1, two attacks) and 681489 (rank 2, three attacks). `AscensionWitchHunterCompletion.cpp` rewrites both
triggers at load into one off-hand 100% weapon strike per cast, so the number of strikes is the number of casts.

`AscensionWitchHunterEvents.cpp` handled both ranks in one `case` that cast 681392 twice. Count of record final08
measured rank 2 at 2.0 strikes per proc against 3.0. Live combat logs show rank 2 as 681489 `SPELL_EXTRA_ATTACKS`
with amount 3 in all 638 events (two players, July 2026).

## Options

- Rank 2 casts its own trigger 681489 three times.
- Rank 2 casts 681392 twice and 681489 once: the same count, but not the spell live shows.
- Restore the stock extra-attack effect: the engine runs extra attacks on the main hand, and it changes the
  strike-as-spell model.

## Decision

The first option (mentor D-128): the shared `case` is split, rank 1 keeps two 681392 casts, rank 2 casts 681489
three times; both still cast Replenishment (1257670) once per proc. 681489 is already excluded from Witch Hunter
event recursion.

## Consequences

- Counted pair 20261115-181525 / 20261115-181631 (worldserver 1b2c523c8b16): `681488 behaviour_metric_delta
  extra_strikes` ok 3.0 / 3.0 against 3.0 (40 procs, 120 strikes; 41 procs, 123 strikes), `681329 ...` ok 2.0 / 2.0
  (22 procs, 44 strikes; 29 procs, 58 strikes), controls 0 procs; the Replenishment labels of both ranks stay ok.
- Per-strike damage parity with live swings (live strikes are `SWING_DAMAGE`, ours are spell hits) is not covered.
