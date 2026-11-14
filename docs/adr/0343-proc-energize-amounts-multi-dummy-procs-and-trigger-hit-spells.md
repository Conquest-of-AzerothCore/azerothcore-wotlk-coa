# 0343. Proc energize amounts, multi-dummy minion procs and trigger hit spells

- Status: accepted
- Date: 2026-11-12

## Context

Overwhelming Force states the amounts its proc restores (2 Runic Power, 2% of maximum mana); a proc rate proves
only that it fires. Putricide's Formula states "up to 3 nearby enemies", which one dummy cannot show. Harrowing
Winds' damage comes from Glacial Impact's triggered hit 707592, not from the cast 704355, and Glacial Impact needs a
frozen target.

## Decision

- `energize_amounts` on a proc entry adds a `proc_energize_amount <power>` expectation (behaviour): the summed
  `spell_energize_total` of the proc spell for that power must equal the count times `expected`, or times
  `floor(max_power x percent_of_max / 100)` read in the same part.
- `extra_dummies` (minion procs) places more dummies at the given distances and reads the proc spell on every dummy;
  `events_per_proc` states the targets per proc.
- `magnitude_ratio` cast entries take `trial_spell` (the hit spell measured) and `target_state_fixture` (the cast's
  target aura state fixture, ADR 0303); `trigger_count` cast entries take `target_state_fixture` too.
- `label_suffix` names a second magnitude or cooldown-gate entry of one aura.

## Consequences

- Overwhelming Force: 20 Runic Power and 56 mana (2% of 2800) per proc in both runs.
- Harrowing Winds: 273 splashes in 273 hits and 0.441 of the hit against 0.5 x 0.88 kept after the partial resist.
- Putricide's Formula with four dummies reads about 5.6 blasts per expected proc against the stated 3 and the code's
  cap of 2: an alert whose cause is not yet established (no fix, no owner question until reproduced and explained).
