# 0404. A script hit states a multiplier

- Status: accepted
- Date: 2026-11-13

## Context

Raise: Gargoyle 500329 states that Command: Gargoyle 707598 deals "50% increased damage for each of your diseases on
the target" (Factor(), AscensionNecromancerContracts.cpp:410-411). A `script_hit` judges the mean hit against the
tooltip value of the hit spell; its record carried a fixed `gate_multiplier` of 1.0, and the measured model of a script
hit (`hits.measured_hit_model`) returned before any multiplier was applied.

## Decision

- A `script_hit` entry takes `multiplier` (default 1.0, positive): its record's `gate_multiplier`, and the rule names
  it.
- `hits.measured_hit_model` scales a script hit's mean by the record's `gate_multiplier`, as it already does for rank
  hits.

## Consequences

- Entries without `multiplier` are judged as before (factor 1.0): Templar `generate --class 19` and `--stack` are
  byte-identical.
- The Gargoyle's hit after one Crypt Plague 570131 on the target is judged at 1.5 times the tooltip value; the entry
  without a disease is the contrast on the same build.
- Mutant: a Gargoyle hit at the x1 tooltip value against the x1.5 model is outside the hit judge's interval (the
  one_disease and command_damage entries read 725 and 483.5 on one build); the two_diseases entry reads x2.0.
