# Expiry below after (`metric_delta` `expiry_below_after`, ADR 0738)

`expiry_below_after: true` is for an entry with an expiry reading (`expiry_wait_ms`, `after_expiry_expected`) and an
`after_at_least` above `after_expiry_expected`. The judge (`compare.judged_metric_delta`) then takes the expired
reading for its direction only: it must lie below the after reading and at or above `after_expiry_expected` (the
floor, the control's level), instead of matching `after_expiry_expected`. The before and after readings are judged as
before. Use it for a decay the tooltip states without a rate. Absent, the judge is unchanged.

Witch Hunter: Unbroken 707407 `decays` (attack power from one hit, lower 4000 ms later, not below the base).
