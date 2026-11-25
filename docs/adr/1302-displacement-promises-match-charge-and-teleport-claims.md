# 1302. Displacement promises match charge and teleport claims

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Rulings: Cultist orchestrator D-39
- Follows [ADR 0739](0739-a-metric-delta-can-judge-the-caster-displacement.md) and
  [ADR 0740](0740-a-displacement-entry-can-judge-its-bearing-from-the-start-facing.md)

## Context

Two Cultist (class 25) movement claims describe live caster displacement using the words `"charge"` and `"teleport"`:

- Dreadfall 806175 (row 409[2]): `"Raise your shield and charge towards an enemy"` (Effect[0] 149 charges the caster to
  the enemy target).
- Dark Veil 520345 (row 133): `"At the end of the duration, if the shield holds, you teleport to them."`
  (`AscensionCultistAuras.cpp:164-172` calls `player->NearTeleportTo(target->...)` on channel expiry when both 520346
  shield effects remain `> 0`).

`metric_delta_options/displacement.py` reads the caster's live `(position_x, position_y, position_o)` immediately before
the trigger cast and `(position_x, position_y)` right before the judged reading, replacing the judged readings with the
measured 2D displacement (and optionally verifying the bearing from the starting facing). This is a live before/after
unit-position behaviour read, not a static readback.

However, `STATE_PROMISES['displacement_2d']` was `r'dash\w*|direction|distance|leap\w*|range|yds?'`, omitting
`charge\w*` and `teleport\w*`, so `coverage.py` classed any `displacement_2d` proof of these two claims as `data`.

## Decision

Widen `STATE_PROMISES['displacement_2d']` in `metric_delta_options/displacement.py` to:

```python
r'charge\w*|dash\w*|direction|distance|leap\w*|range|teleport\w*|yds?'
```

## Finished-class audit check

Every finished class (`felsworn`, `necromancer`, `sun_cleric`, `templar`, `witch_doctor`, `witch_hunter`) was scanned
for every behaviour entry using `displacement` / `displacement_2d` and checked against every clause in its ledger:

- `felsworn`: 4 displacement labels (`805244` x2, `806109` x2) — 0 reclassified.
- `necromancer`: 0 displacement labels — 0 reclassified.
- `sun_cleric`: 1 displacement label (`802161`) — 0 reclassified.
- `templar`: 0 displacement labels — 0 reclassified.
- `witch_doctor`: 0 displacement labels — 0 reclassified.
- `witch_hunter`: 4 displacement labels (`789256`, `500085` x3) — 0 reclassified.

Total finished-class rows reclassified: **0**. Generated scenarios of every finished class are untouched.

## Consequences

- Opt-in audit promise widening only; zero generated scenario changes and zero finished-class reclassifications.
- Closes Cultist Dreadfall 806175 row 409[2] (`charge_displacement`, leaving the separate supported `pass_through` alert
  on row 409[0] uncounted) and Dark Veil 520345 row 133 (`teleport_holds` and `teleport_broken_control`).
- `metric_delta_options/test_displacement.py` verifies promise matching for `"charge"`, `"teleport"`, and non-movement
  refusal.
