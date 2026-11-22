# Vehicle landed (`metric_delta` `vehicle_landed`, ADR 1062)

`vehicle_landed` is `true`, on an entry whose `strike` hits the caster (no `owned_entry`). The scenario reads
`aura_apply_count` of the strike spell on the caster three times: right after the settle wait, right after the before
reading, and after the last treatment reading (the expired reading when there is one). No read sits between a strike
and a timed reading, so game-time stamps and readings keep their places. A phase with N strike casts needs at least
N applications between its two reads, else the run is `unmeasured`: the vehicle missed, was dodged or parried, and
the reading is not the effect.

Named point: `verdict(verdict, run, value)`, called by `metric_delta_options.option_verdict`; `fixtures` adds the
reads and counts each phase's vehicle casts, `model` carries the counts.

Sun Cleric: Valkyr's Grip 807507 and 807873 `window_held` and `window_gone` (Disarm 8379, DmgClass 2 melee).
