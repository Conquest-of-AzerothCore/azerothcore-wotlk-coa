# 0185. Free cost gates and charging setup casts

- Status: accepted
- Date: 2026-11-12
- Extends: ADR 0137 (group-target and cost-gate kinds)

## Context

Determined 705256: "Your Temple Guardian now makes your next ability within $681136d free of cost." The duration claim
"within $681136d" was a DBC readback. A `cost_gate` with `aura_duration_ms` proves a window from a real setup cast, but
three limits stopped it:

- a cost reduced to 0 has no power level below it, so `cost_gate_levels` refused the entry (`NotModelled`);
- the ally player was added only when the entry's own `target` was `ally`, although the docs said a setup cast at
  the ally adds it; a gated spell at the dummy with a setup cast at the ally failed with an unknown target;
- Temple Guardian 803792 is a charge (5 to 30 yd) with charges: without a step back it fails too close, and by the
  fourth arm its charges are spent, which left the caster out of range (`SPELL_FAILED_OUT_OF_RANGE`).

## Options

1. A new kind for a free next ability. It repeats the arms of `cost_gate`.
2. Fix the three limits inside `cost_gate`.

## Decision

Option 2.

- A power reduction to exactly 0 gives the arms `without`, `with`, `next`, `held` and `expired`, with no `beyond`.
- The ally player is added when the entry's target or any setup or after cast targets the ally.
- A setup cast at the ally that closes the distance is preceded by the step back (`CHARGE_OFFSET_YD`), and the
  optional `restore_charges` restores the setup spell's charges before it.

No existing entry reaches these cases: the 1432 class scenarios of the checkpoint regenerate byte-identical.

## Consequences

- Determined reads 85 (no power) without the talent, 0 after a Temple Guardian, 85 on the next attempt, 0 at 4700 ms and
  85 at 5300 ms after it.
