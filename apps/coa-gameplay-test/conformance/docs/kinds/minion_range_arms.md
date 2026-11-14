# Minion range arms (`behaviour_metric_delta`, `kind: "minion_range_arms"`, ADR 0594)

A raised minion (`raise_spell`, entry `minion_entry`) is sent onto the dummy with `command_spell`; the caster then
steps along the line past the dummy to `near_yd` from it and casts `spell` (near arm), then to `far_yd` and casts again
(far arm, the control). Each arm reads the caster's distance to the dummy, the minion's distance to the caster
(`owned_creature_distance_2d`) and the `observe_spell` heals over `wait_ms`.

Verdict: the minion must stay under `radius` in the near arm and more than `radius` + 3 yd (an object size margin) in
the far arm, or the entry is unmeasured; then the near minion is healed and the far one never.
