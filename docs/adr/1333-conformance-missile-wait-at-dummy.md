# 1333. Opt-in `missile_wait_at_dummy` for hostile missile aura reads in value scenarios

- Status: accepted
- Date: 2026-11-27

## Context

`values.missile_wait_ms` returns `0` when a spell is cast from `DUMMY_DISTANCE` (`3 yd`), keeping melee-distance
value scenarios across the six already-snapshotted classes byte-identical. When a hostile spell has `Speed > 0`
and `RangeMin[0] == 0` (so `cast_distance` keeps `DUMMY_DISTANCE`) AND its `value_scenario` reads an applied aura
(`aura_amount`, `aura_duration_ms`, or `aura_amplitude_ms`) on the dummy — such as Felsworn's *Cripple* (`704371`,
`Speed = 50.0` yd/s) — the aura read executes on the same server tick as the cast before the missile lands (`60 ms`
later), reporting `aura_present = 0` and false alerts on `aura_amount` and `aura_duration_ms`.

## Decision

Add an opt-in boolean class-file flag `"missile_wait_at_dummy": true` (default `False`, validated strictly as `bool`
in `values.missile_wait_at_dummy`). When enabled and a hostile spell's `value_scenario` includes an aura read in
`after_cast`, `value_scenario` passes `allow_dummy=True` to `missile_wait_ms`, emitting the existing `missile travel`
wait step (`ceil(max(distance, 5.0) / speed * 1000) + CAST_MARGIN_MS`). `compare.elapsed_bound` already folds that
wait's `elapsed_ms` into the `aura_duration_ms` window `W`.

## Consequences

- Existing class files without `"missile_wait_at_dummy": true` produce zero snapshot drift.
- Felsworn (`felsworn.json`) opts in, resolving *Cripple* `704371`'s `aura_amount` and `aura_duration_ms` reads
  directly against the landed aura instead of dropping them as generator false alerts.
