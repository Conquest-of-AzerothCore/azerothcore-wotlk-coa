# 0140. Periodic-dispel kind and the chunk 2 review's control arms

- Status: accepted
- Date: 2026-11-11

## Context

The independent review of lean Templar batch 1, chunk 2 (`lean/batch1-c2-review.md`) found three clauses counted
with a proof weaker than their words:

- **Testament of Fortitude 500678**, "Each second you will also remove 1 disease effect from yourself."
  - The entry read Frost Fever 55095 before the cast and 15200 ms after it, on the real clock only.
  - Frost Fever lasts 15000 ms (`DurationIndex` 8), so a natural expiry gives the same reading.
  - "Each second" and "1 disease" were not measured.
  - The entry's rationale, that the aura 227 tick never fires on the simulated clock, is contradicted by Righteous
    Custodian's 227 ticks in the same chunk.
- **Pious Sweep 520034**, "or affected by Tranquil Circle.": both arms learned the talent, so a circle that added
  25% on its own would pass.
- **Vindication 573324** `${$m1+0+$AP*0.285+$SP*0.75}`: the hit model ran at 0 spell power, so the $SP*0.75 term was
  never exercised.

## Decision

- New kind `periodic_dispel` (judged exactly, `behaviour_cast_condition`):
  - at least two fixtures of the dispelled type;
  - a time-matched control arm with no cast;
  - with the cast, readings before the first period and after each period.

  Each reading is the sum of the fixtures, because the removal order is not fixed:
  `compare.behaviour_cast_gate_verdict` sums `sum_labels` when the model names them. Testament of Fortitude uses Frost
  Fever and Blood Plague on the simulated clock, and the old `dispel_removal` entry is removed.
- Pious Sweep gains the `circle_without_talent` arm: the circle with the talent unlearned, expected +0%.
- Vindication's ledger entry declares two claims: the base and attack power terms (hit_mean) and the $SP*0.75 term,
  which stays data. The clause is data conformant until a hit reading at a known spell power exists.
- With a `talent_aura`, `cost_gate` reads the aura's presence before each talent arm's attempt (review M6).

## Consequences

- Testament of Fortitude no longer needs a real-clock run.
- Measure c loses Vindication as a full behaviour test, because only part of its formula is measured.
- The `dispel_removal` kind and its `gameplay_clock` field stay for other entries. Their tests use a synthetic
  real-clock entry.
