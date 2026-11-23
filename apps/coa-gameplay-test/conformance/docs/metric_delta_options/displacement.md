# Displacement (`metric_delta` `displacement`, ADR 0739)

`displacement: {}` is for an entry whose metric is the caster's `position_x` without fields. The scenario reads the
caster's `position_x`, `position_y` and `position_o` right before the last trigger cast of each phase (right before
the reading when the phase casts none) and `position_x` and `position_y` right before each judged reading
(`<label> start x`, `... end y`). `run_values` replaces each judged reading with the 2D distance between the two
points, so the plain judge (`expected`, `expected_gain`, `expected_ratio`, `after_at_least`, `tolerance`) judges the
displacement of each phase. The model names the evidence metric `displacement_2d`, a state the module declares with
the entry's own `position_x` reads (merged through `metric_delta_options.option_rows`, so the class files' metrics stay
classed), promised by `dash\w*|direction|distance|leap\w*|range|yds?`. A missing position read leaves
the judged reading missing. Absent, the scenario is unchanged.

`{"bearing": degrees, "bearing_tolerance": degrees}` (ADR 0740; tolerance default 15, in (0, 90)) also judges the
treatment displacement's direction from the caster's facing at its start (`position_o`): it must be at least 1 yd
long and point within the tolerance of `bearing` (counterclockwise from the facing, -180 to 180), else `alert`.

Witch Hunter: Vault 500085 `strafe_left` (90), `vault_backward` (180) and `vault_speed` (ratio 1.5 at +50% run
speed); Night Walker 789256 `vault_range` (Vault 15 yd without it, 18 with it, the D-9 start point).
