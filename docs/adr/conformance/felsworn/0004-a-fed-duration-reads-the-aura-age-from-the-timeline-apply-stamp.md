# 0004. A fed duration reads the aura's age from the timeline apply stamp

- Status: proposed (class ADR, numbered at merge)
- Date: 2026-11-23
- Decided by: mentor D-21 (void when the aura's age at the first read exceeds 100 ms or cannot be read, else the
  apply-stamp route of ADR 1236), review fw-rt1d2 I-1, controller go

## Context

The D-21 guard of ADR 0003 computed the aura's age as the expected duration less the remaining duration. That equals
the age only when the real duration equals the expected one: a stamp stale by 400 ms on a 6400 ms aura reads
6000 ms remaining, an age of 0, and the bracket (which also sees only the remaining time) passes 6000. The harness
gives no maximum duration or apply time for an aura on any holder (`aura_duration_ms` is `Aura::GetDuration`;
`owned_creature_aura_max_duration_ms` reads owned creatures only).

## Options

- A harness read of the live aura's maximum duration or apply time: new harness C++ (G-39).
- State the residual and accept expected less remaining as the age proxy.
- The encounter timeline of ADR 1236: `OnAuraApply` stamps every apply in `GameNowMs`, the base of `game_time_ms`.

## Decision

The fed treatment arm reads `game_time_ms`, then `encounter_start` on the dummy, before its loop; after the stop it
reads `timeline_count` and `timeline_first_ms` of `aura_applied` for the aura on its holder. The age at the first poll
is at most the poll's game time less the start read and the first stamp. Above 100 ms, a missing stamp, a stamped
apply count other than one, or no remaining duration voids an `ok`; the bracket is unchanged. Python only.

## Consequences

- Test: `FeedTests` in `kinds/test_last_application_expiry.py`, with the 400 ms stale stamp on a 6400 ms aura that
  passed the derived age and is now `unmeasured`.
- The derived age no longer narrows the pass band to [E, E + 100] for the remaining read (review M-1).
- Fed scenarios hold an `encounter_start` and run exclusive in a simulated-clock batch; only Felsworn entries feed.
- Non-fed scenarios are unchanged.
