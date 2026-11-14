# After-trigger strike (`metric_delta` `after_trigger_strike`, ADR 0606)

`after_trigger_strike` is `{"spell": ID, "delay_ms": N, "count": 1, "wait_ms": 300}`: in the treatment phase only,
`delay_ms` after the trigger cast, the striker (the `strike` fixture creature) casts `spell` at the caster `count`
times, `wait_ms` apart. The control phase makes the same trigger cast and is not struck, so a unit the trigger creates
exists in both phases and only the treatment is hit. An entry may not set both `strike` and `after_trigger_strike`.

Named point: `after_trigger_steps(spec, value, after)`, called by `metric_delta_options.option_after_trigger_steps`
right after the trigger cast of each phase; `fixtures` adds the striker.

Necromancer: Gravebound Champion 805049 (the Champion's health after a strike at the caster, claim 353.2).
