# Dummy casts at the caster (`metric_delta` `dummy_casts_at_caster`, ADR 1112, provisional)

`dummy_casts_at_caster` is `{"spell": id, "casts": n, "gap_ms": ms, "lead_ms": ms}` (1 to 20 casts at least 1000 ms
apart). In each phase the dummy casts `spell` at the caster `casts` times, `gap_ms` apart, as an ordinary cast
(the harness creature cast with `triggered: false`, ADR 1110): after each trigger cast, `lead_ms` later, through the
named point `after_trigger_steps`; in a before phase that does not cast the trigger (`trigger_only_after` or
`cast_in_before: false`) at the point of the cast, through `phase_steps`. The trigger must target the dummy. Absent,
the scenario is unchanged.

Use it for a claim about what a unit does when its enemy casts at it: a script hook that skips triggered casts sees
these casts, which the default (triggered) creature cast hides.

Witch Doctor: Fool's Play 681007 `mirror` (the dummy casts Damage 100 (TEST) 2653 at the caster 8 times; the copy
casts it back at the dummy: 0 hits without the copy, 4 to 8 with it).
