# Hit periods (`behaviour_metric_delta`, `kind: "hit_period"`, ADR 0552)

A cast's hits on the dummy are polled with game-time stamps; (last - first) / (n - 1) is judged with the
`cast_period` judge (its model's `kind` is `cast_period`) against `expected_ms` in the G-19 band (Soulfreeze
801724's ticks).
