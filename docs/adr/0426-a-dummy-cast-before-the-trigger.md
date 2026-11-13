# 0426. A dummy cast before the trigger

- Status: accepted
- Date: 2026-11-13

## Context

Heartchill 801739: "Chill an enemy's heart, interrupting their current spell cast. Successfully interrupting a spell
also reduces their movement speed and haste by $803677s1% for $803677d." The slow is cast only from
OnSpellSuccessfulInterrupt (AscensionNecromancerAbilities.cpp:239-245), so both claims need a target that is casting
when Heartchill lands. `metric_delta` had no step that makes the dummy cast, and the `casting` read had no evidence
class.

## Decision

- `metric_delta` takes `target_casts_before`: spells the dummy casts on itself, each followed by a 300 ms settle, right
  before every trigger cast. It needs the dummy as the trigger's target and no attack phases. Without the field every
  scenario is byte-identical (`generate --class 19`, `--stack`).
- `coverage.METRIC_EVIDENCE` lists `casting` (the unit's current spell) as an event read.

## Consequences

Heartchill reads the dummy's Evocation 12051 channel (1 without Heartchill, 0 after it), its run speed (0.2 of it) and
803677 on it, with a no-channel control that leaves no 803677. Tests: `TargetCastTests` (test_behaviours.py).
