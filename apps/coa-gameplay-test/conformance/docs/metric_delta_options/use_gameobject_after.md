# Use gameobject after (`metric_delta` `use_gameobject_after`, ADR 1139)

`use_gameobject_after` is `{"entry": id, "uses": n, "gap_ms": n}` with an optional `destroy_item` and `lead_ms`, for an
entry whose treatment cast creates a gameobject (`trigger_only_after`). After the treatment cast the caster uses its
own object of `entry` `uses` times through the client use handler (the harness `use_gameobject`), the first `lead_ms`
(default `gap_ms`) after the cast, the others `gap_ms` apart; with `destroy_item` each item a use gives is destroyed
`gap_ms` later, so a stack-one item never fills the bags. The module also gives the reads
`owned_gameobject_count` (event) and `gameobject_remaining_ms` (state, promise `lasts?|duration`) their
`coverage.METRIC_EVIDENCE` rows. With `"user": "ally"` (ADR 1174, provisional) the
[`grouped_ally`](grouped_ally.md) uses the caster's object instead (the harness `use_gameobject` with
`owner`) and destroys the items it gets. Absent, the scenario is unchanged.

Named point: `after_trigger_steps`.

Witch Doctor: Mojo Cauldron 807908 `created`, `lasts`, `mojo_item`, `mojo_cast`, `charges_left` and
`charges_spent`; `ally_mojo` and `stranger_mojo` with `user: ally`.
