# Minion travel ratios (`behaviour_metric_delta`, `kind: "minion_travel_ratio"`, ADR 0594)

Two creatures, `slowed_entry` and `control_entry` (the control without the slow), are raised (`raises`:
`[spell, caster|dummy, power?]`) and `command_spell` sends both at a stationary dummy `far_yd` out. Every `poll_ms` the
game time and each creature's `owned_creature_distance_2d` to that dummy are read; each speed is the least-squares slope
over the reads while the creature is more than 3 yd away and still closing at least half its median step (the stalled
tail at melee reach is left out). The slowed speed over the control speed must be `expected_ratio` in the G-19 band
(5% of the ratio). The run speed rates of both are read for the explanation.
