# 0028. A Soulfreeze chain is read alone on a frozen dummy

- Status: accepted
- Date: 2026-11-13

## Context

Soulfreeze 572023 launches a chain (801724, a 1000 ms periodic trigger for 3000 ms) whose hits (801728) need a Frozen
target (TargetAuraState 4) and, with the talent known, re-roll another chain on every Frost hit on a Frozen target. Over
many procs the hit totals did not give the per-hit amount, the period or the count (claim 397.0, tool gap "stable
frozen fixture", route pending since batch M).

## Decision

- Design 1, class-file only (no tool change): the caster casts 801724 itself (a real cast, the proc's own spell; the
  proc rate stays with the 572023 proc entry) at a dummy held Frozen by Ice Lock 22856 (ADR 0491), without 572023
  known, so exactly one chain runs. metric_delta reads stamped in game time (ADR 0501): the first hit's amount, two
  brackets around the first and the second hit, the chain aura's end and the hit count.

## Consequences

- 801724 entries (prove-9): first hit 353 (353.75 truncated), hits about 330 ms after each trigger (801728 Speed 17),
  the second hit 950-1050 ms after the first at the read times, the aura gone in (2950, 3000] ms, 3 hits and no fourth.
- The per-tick Runic Power (398.0) is not judged: 800344 rolls 30-80 internal per tick, live agrees, the tooltip shows
  3; an owner question candidate.
