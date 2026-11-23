# 1219. A metric delta attack phase can swing at a second target

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22

## Context

Sun Cleric Valiance 680643 (ledger row 195, claim 2): "your first auto attack on a target hits twice". The
`first_extra` entries attack one dummy and read one extra attack (681472) per phase; whether a second target gets
its own extra attack, and its own 681531 marker (owner ruling O-21, Sun Cleric ADR 0024), was not expressible: an
`attack_swings` phase attacks the dummy only. Mentor ruling D-216.

## Options

- A new kind with its own attack phases: duplicates the metric_delta with/without frame.
- An opt-in `metric_delta` option that appends, to each attack phase, a `stop_attack` and an attack on an
  `area_dummies` copy for the same wait, with existing harness steps only.

## Decision

The option `second_swing_target` (`metric_delta_options/second_swing_target.py`), applied at the `fixtures` point after
`area_dummies` (ORDER 7 after 6). It finds exactly the two attack blocks the `attack_swings` path writes, inserts the
second block after each, requires the area dummy at the dummy's distance, and recomputes the timeout.

## Consequences

- Absent by default: no finished-class entry writes it; the finished classes regenerate byte-identical.
- Seeded tests (`metric_delta_options/test_second_swing_target.py`): parse, the step order of both phases, the
  default, refusals, and the judge: 2 casts pass, the one-per-caster (1) and one-per-swing (6) mutants alert.
- The readings are existing event metrics (`spell_cast_count`, `aura`); no evidence row is added.
