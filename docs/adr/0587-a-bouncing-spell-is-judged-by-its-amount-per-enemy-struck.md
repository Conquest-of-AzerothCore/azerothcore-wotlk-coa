# 0587. A bouncing spell is judged by its amount per enemy struck

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0581

## Context

Necromancer claim 116.0, Crypt Keeper 560596 "at ${-($800343f1-1)*100}% reduced value per enemy struck": Crypt Swarm
800343 has EffectDamageMultiplier[0] 0.7, applied once per jump (`Spell.cpp:8635-8636`), so the second enemy takes
0.7 and the third 0.49 of the primary's hit. `fixed_count` (the bounces entry) reads how many dummies are struck,
not the amount each takes (gap T2 of the c4 route designs).

## Options

1. A per-dummy amount read added to `fixed_count` (a built-in kind of `behaviours.py`).
2. A kind module `bounce_amounts` (ADR 0581).

## Decision

Option 2. `kinds/bounce_amounts.py` places the primary and the further dummies at stated distances and one far dummy,
casts the spell's channel without the talent (control) and with it (treatment), and reads every dummy's damage total
and hit count of the bouncing hit after each arm. The verdict needs the control to strike the primary only, every
further dummy struck in the treatment and the far dummy never; the treatment's per-hit means, largest first, divided
by the primary's, must lie within 5% (G-19) of the DBC multiplier raised to the jump number. Sorting by mean makes the
judge independent of which dummy the engine picks first.

## Consequences

- The amounts are judged on plain hits only when the entry removes crits and partial resists with its caster auras.
- A dummy that changes its place in the jump order between casts mixes two amounts into its mean and alerts.
