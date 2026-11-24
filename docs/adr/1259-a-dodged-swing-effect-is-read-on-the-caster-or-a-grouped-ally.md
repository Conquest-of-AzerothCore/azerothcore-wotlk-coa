# 1259. A dodged-swing effect is read on the caster or a grouped ally

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-23

## Context

Betrayer 300476 casts 520256 on the caster when it dodges (AscensionFelswornEvents.cpp:223-224). 520256 is an area
aura on friendly units within its radius (TargetB 30 UNIT_SRC_AREA_ALLY) that raises their critical strike chance for
its duration. Illidari Training 805249 casts the energize 521210 on every dodge. The avoided proc trigger
(`proc_avoided`, ADR 0900) and `triggers` count events per dodge. `radius_edge` and `party_stat_ratio` start from a
cast or a learn. No kind reads a grouped ally's aura, stat or remaining duration, or the energize amount per event,
after dodged swings.

Options considered: an `avoided` trigger on `radius_edge` and `party_stat_ratio` (shared kinds whose judges would gain
a second trigger path); an amount field on `triggers` (a judge change on a shared core module); a new kind module.

## Decision

- Behaviour kind `avoided_swing_reads` (module `kinds/avoided_swing_reads.py`, ADR 0581 hooks; doc
  `docs/kinds/avoided_swing_reads.md`). It reuses the striker fixtures, engage, avoidance and guard steps of
  `proc_avoided` with dodge 100 and parry 0, a control window before the passive is learned and a treatment window
  after it (mentor D-67), and a 20 yd relocation that quiets the strikers before the reads.
- `read` chooses one judged quantity, its expected value read from the server DBC of `observe_spell`: `aura_edge`
  (allies at the radius minus and plus a margin), `stat_delta` (a grouped ally's stat, treatment less control),
  `duration_max` (the largest remaining duration read after every window, band one window and one tick below the
  duration) and `per_event` (energize total over count, exact).
- Existing checks and metrics only: `behaviour_metric_delta`, with the metric in the model (`aura`,
  `melee_crit_chance`, `aura_duration_ms`, `spell_energize_total`), all present in `coverage.METRIC_EVIDENCE`.

## Consequences

- Additive module: no shared core file changes, no finished-class scenario changes (classes 15, 19, 19 --stack, 23
  and 27 regenerate byte-identical).
- Tests: `AvoidedSwingReadsTests` (kinds/test_avoided_swing_reads.py), with a wider and a narrower radius, a half crit
  gain, 9 s and 11 s durations and a 2 Energy amount that must alert.
- The off-hand weapon damage of 804336 (normalized and percent weapon effects) is not read: it needs a judge change in
  `script_hit` and stays a reported gap.
