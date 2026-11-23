# Shot ramp (`shot_ramp`, ADR 0910)

A channel whose every shot adds a stack that raises the next shot's damage. The entry names `cast_spell` (the
channel), `shot_spell` (the shot it triggers), `stack_spell` (the stacking aura: `EffectBasePoints[0]` + 1 per stack,
`StackAmount` the cap), `shots_per_cast`, `dummy_distance`, and optionally `casts` (3), `sequences` (4), `reset_ms`
(2500), `cast_power`, `caster_auras`, `target_auras` (set on the dummy before every cast) and `learn`.

Each sequence casts `cast_spell` `casts` times, one cast every `shots_per_cast` x `EffectAmplitude[0]` ms, so the shots
sit on one grid. Half a period after each landing (travel from `Speed`) it reads the `shot_spell` damage total and count
of non-critical, unblocked shots and the count of every shot. After the last shot it reads the `stack_spell` stacks on
the caster. One control sequence runs before the entry's spell is learned, then `sequences` with it learned.

The judge needs one shot per window (else `unmeasured`), a flat control, the stacks read 0 after the control and `cap`
after every treatment sequence (else `alert`), the treatment first shot equal to the control's, and shot n (from 0)
equal to the first shot times `1 + per_stack x min(n, cap)` within 1 + the multiplier points (a rounded or floored
amount). Critical or blocked shots are left out; every stack count 0 to cap and one beyond need a plain shot over the
sequences, and the first shot must be large enough for the band to tell the stated step from one 5 points lower, or the
label is `unmeasured`. Labels: `<spell> behaviour_metric_delta <suffix>` (mean per-stack step) and `<suffix>_max`
(plateau bonus, shot over first shot minus 1, over the first shot).

Witch Hunter: Arbalest Mastery 706240 "Each subsequent shot of a Witchbane cast deals $706241s1% more damage, up to
a maximum of ${$706241u*$706241m1}%." (claims 279.0 and 280.0).
