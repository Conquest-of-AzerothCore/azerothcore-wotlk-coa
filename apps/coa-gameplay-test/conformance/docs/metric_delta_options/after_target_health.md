# After target health (`metric_delta` `after_target_health`, ADR 1131)

`after_target_health` is a positive health below the dummy's 50,000,000. At the start of the treatment phase the
dummy's health is set to it (the harness creature `set_health`); the control phase casts at the dummy at full
health. With a value of 1 the treatment cast kills the dummy and the control cast cannot, for a claim about a kill by
the cast. The entry needs the dummy as its target and both phases cast; it refuses `target_health_pct` and
`phase_target_health_pct`. Absent, the scenario is unchanged.

Named point: `phase_steps` (the treatment health step).

Witch Doctor: Shadowflare 501146 `kill_spirit` (a Spirit 561136 after the cast that kills the dummy, none after the
one that does not).
