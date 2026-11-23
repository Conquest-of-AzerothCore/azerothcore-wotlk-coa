# Caster health entered from a percent (`metric_delta` `caster_health_from`, ADR 1197)

`caster_health_from` is a percent, 1-100, on an entry that sets `caster_health_pct` (a different percent) and
`disable_regeneration`. At the start of each phase the caster is set to that percent of the health fixture and held
there 1000 ms, then `caster_health_pct` is set before the trigger as usual. A health state kept with hysteresis is
then entered from above (a higher entry percent) or from below (a lower one), so a read inside the band shows which
side the state remembers. It adds no check. Absent, the scenario is unchanged.

Sun Cleric: Fortuitous 561328, Glare cast time read at 81% from 50% (on), 79% from 90% (on), 75% from 90% (off) and
79% from 50% (off), the four hysteresis edges of `AscensionSunCleric.cpp` `Refresh` (on above 80%, off at or below
75%, b2ad6f76d6).
