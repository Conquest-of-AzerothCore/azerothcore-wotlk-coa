# Last-application expiries (`behaviour_metric_delta`, `kind: "last_application_expiry"`, ADR 0593)

An aura applied several times at unknown moments (one March of the Dead walker after another) is timed from its last
application. `trigger_spell` is cast at the dummy before `gate_spell` is learned (control) and after it; every
`poll_ms` the game time, the dummy's `aura_apply_count` of `aura` (a new aura and every refresh) and its presence are
read over `control_window_ms` and `window_ms`.

The last application lies between the two reads where the count last rises; the aura's removal between the last read
with it and the first without. The bracket `(gone_prev - last, gone - last_prev)` must lie inside the G-19 band around
`expected_ms`; one entirely outside it alerts, one straddling an edge is unmeasured. A control application alerts; an
aura still on past the band at the window's end alerts.
