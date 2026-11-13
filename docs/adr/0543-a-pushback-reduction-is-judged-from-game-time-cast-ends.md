# 0543. A pushback reduction is judged from game-time cast ends in one scenario

- Status: accepted
- Date: 2026-11-13

## Context

Icebound Champion 807813 "reduces the pushback suffered from damaging attacks while casting by $807812s1%" (50). The
batch M side c entries read it as six held / done pairs across several scenarios at nominal wait sums. ADR 0485 found
that harness waits run past their nominal length, so a cast-time claim counts only after a game-time judgement, and
ADR 0501's per-reading windows cannot judge a ratio of three cast ends. The mentor approved one design: in one
scenario, an unhit cast, a hit cast without the Champion and a hit cast with a real Champion, the casting state polled
with game-time stamps and the hit itself stamped, the reduction judged in the G-19 band 47.5..52.5 with no widening,
and the arm invalid (not failed) when the two hits land at different game-time offsets into their casts.

## Decision

- A behaviour kind `pushback_reduction` builds that scenario: each cast start, the moments just before and after the
  striker's cast step, and every poll of `casting` (1 ms wait steps over a window per phase) are read with the
  read-only `game_time_ms` metric (ADR 0485).
- The judge takes each end as (last casting poll, first idle poll] after its cast start, brackets the reduction
  1 - (reduced - unhit) / (hit - unhit), and returns `ok` inside the band, `alert` outside it, `measured` across an
  edge. A hit cast with other than one landed strike, or strikes at offsets further apart than the widest poll
  bracket, is `unmeasured`.
- No harness C++ change. Other entries generate the same scenarios (Templar `generate --class 19` and `--stack`
  byte-identical).

## Consequences

- Ledger claim 360.3 counts only the new label; the six nominal-wait labels stay as context. The working evidence
  (50.3..52.2) leaves thin headroom under 52.5, which the ledger reason states.
- Tests: `PushbackReductionTests` (test_behaviours.py).
