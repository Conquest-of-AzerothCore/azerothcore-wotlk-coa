# 0720. A cooldown reset rate can pool identical cases

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

A 15% reset chance needs 8461 trials in its G-20 band; Desecrate's 1.5 s global cooldown puts them at 3.5 hours of game
time, past the one-hour accelerated case limit and the 10000-step limit (c11-tool stop on claim 8.0 for the 5% case,
c11-bk on 68.0). The kind judged one case only, and its cases were capped at 10 minutes. Mentor decision D-172 (c12
tool batch item 13, `pool_cases N`).

## Options

- The behaviour generator's existing `parts` (N identical cases named `part 1..N`) with a `POOLED_JUDGE` for the kind,
  which `compare` calls only when every part ran.
- A new `pool_cases` field: the same mechanism under a second name.

## Decision

The first option: `parts` on a `cooldown_reset_rate` entry, `casts x parts` checked against the band's trials, the
pooled judge summing hits and resets over the parts (a control reset in any part alerts), and the contract stating the
pooled count and the residual failure probability (at most 1%). The case limit is raised to the accelerated hour; the
computed timeout of every existing case is unchanged.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (Unholy Runes 561353 has one part; its timeout is
  `waited + margin` either way).
- Seeded tests: a pooled rate off the band and a control reset in one part alert; too few pooled casts are refused.
- Witch Hunter: `504645 behaviour_metric_delta reset_rate` (4 parts of 2120 Desecrates, 803166 and 400 raw Rage
  before each cast).
