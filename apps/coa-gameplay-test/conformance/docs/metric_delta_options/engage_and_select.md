# Engage and select (`metric_delta` `engage_and_select`, ADR 1137)

`engage_and_select` is `{"spell": id, "gap_ms": n, "select_before": unit, "select_after": unit}` for an entry with
[`area_dummies`](area_dummies.md). After each trigger cast the caster selects `select_before` (control) or
`select_after` (treatment), then casts `spell` at every area dummy and at the dummy, `gap_ms` apart with the cooldown
reset, so the caster is in combat with every dummy in both phases and only the selection differs. It needs both
phases cast. Absent, the scenario is unchanged.

Named point: `after_trigger_steps`.

Witch Doctor: Serpent Ward 500960 `focus_primary` and `focus_control` (the ward's attacks 573055 land on the selected
one of two engaged dummies).
