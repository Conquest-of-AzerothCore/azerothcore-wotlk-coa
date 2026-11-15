# 0189. Dispel-removal arms

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0188 (Silverhand Incantation removes Sacred Restraint from an ally)

## Context

Claim 329, Silverhand Incantation 801465: "removing Sacred Restraint from you and them if they are an ally." The fix of
ADR 0188 is proven by a catalog regression, which the clause ledger cannot label. The `dispel_removal` kind reads a
debuff going from present to absent after a cast, but only on the cast's target, with no control.

## Options

1. A new kind for a removal on two units with controls. It repeats the debuff reads and the metric-delta judge.
2. Optional `arms` on `dispel_removal`.

## Decision

Option 2. Each arm (`name`, `target` `ally` or `dummy`, `removed`, optional `away_yd` and `refused`) sets the debuffs
on the caster and on its target, reads them, steps `away_yd` back in steps of at most 20 yd, casts at the target, reads
the cast's `cast_failure` (judged exactly against `refused`, default 0) and the debuffs again (0 when `removed`,
else 1), then steps forward again. Each reading is a `behaviour_metric_delta` verdict with the before reading 1.
Without `arms` nothing changes, and existing scenarios regenerate byte-identical.

## Consequences

- Silverhand Incantation, on the fix build a72fcf65d56d: failed (60 yd) cast_failure 97, both keep 102208; ally cast 0,
  both lose it; hostile cast 0, both keep it.
