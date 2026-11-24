# Ended read (`metric_delta` `ended_read`, ADR 1247)

`ended_read` is `{unlearn, wait_ms, duration_ms}`, with `wait_ms` longer than `duration_ms`, the DBC duration of the
aura that carries the effect. After the after reading the scenario unlearns each spell of `unlearn`, waits `wait_ms`
and reads the entry's metric again (`<spell> <metric> ended`).

The verdict keeps the base verdict when the ended reading equals the before reading of the same scenario within the
entry's tolerance (the float tolerance without one), and is `alert` otherwise; a missing reading is `unmeasured`.
The option requires the default gate timing and refuses `expiry_wait_ms`, attack swings and `setup_only_after`.

Named points: `parse`, `check`, `fixtures`, `model`, `verdict`.

Felsworn: Fel Monstrosity 500067 size (`object_scale`, ratio 1.10), 500076 lasting 11000 ms (SpellDuration 38).
