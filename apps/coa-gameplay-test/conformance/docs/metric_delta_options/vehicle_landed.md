# Vehicle landed (`metric_delta` `vehicle_landed`, ADR 1231)

`vehicle_landed` is `true` or `{"max_step_ms": <positive ms>}`, on an entry whose `strike` hits the caster (no `owned_entry`). The scenario reads
`aura_apply_count` of the strike spell on the caster three times: right after the settle wait, right after the before
reading, and after the last treatment reading (the expired reading when there is one). No read sits between a strike
and a timed reading, so game-time stamps and readings keep their places. A phase with N strike casts needs at least
N applications between its two reads, else the run is `unmeasured`: the vehicle missed, was dodged or parried, and
the reading is not the effect.

With `max_step_ms`, a reading whose bracket rests on one world step of at most that many ms (a `window_gone` age of
at most the stamped gap less `after_trigger_ms` plus one step) also needs the run's recorded `max_step_ms` at or below
the bound: unrecorded or above it, the run is `unmeasured`. The scenario contract states the bound; the steps do not
change.

Named point: `verdict(verdict, run, value)`, called by `metric_delta_options.option_verdict`; `fixtures` adds the
reads and counts each phase's vehicle casts, `model` carries the counts.

Sun Cleric: Valkyr's Grip 807507 and 807873 `window_held` (`true`) and `window_gone` (`max_step_ms` 25), Disarm
13534 (DmgClass 0, aura only); Solar Guardian 704581 `window_held` and `window_gone` (`max_step_ms` 25), Stun 2880.
