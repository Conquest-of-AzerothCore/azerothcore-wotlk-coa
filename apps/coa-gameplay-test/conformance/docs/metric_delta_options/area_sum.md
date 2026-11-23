# Area sum (`metric_delta` `area_sum`, ADR 0998)

`area_sum: true` (needs `area_dummies`, and the dummy named once: as `measure_actor`, for a read on the creature such
as `aura`, or as `fields.target`, for a read about it such as `spell_damage_total`) repeats the entry's read right
after each judged reading (before, after, expired) with each area dummy in the dummy's place, labelled `<reading>
area1`, `<reading> area2`, ... The judge sees the dummy's read plus every area read in place of the reading, so a stated target count
("up to 5 enemies") is judged over all the creatures at once. A missing part leaves the reading missing (the plain
judge then alerts on the missing measurement). It cannot be combined with `fields_sum`. Absent, the scenario is
unchanged.

Named point: `run_values(values, model)`, called by `metric_delta_options.option_run` before the plain judge of a
behaviour `metric_delta`; `fixtures` adds the reads.

Witch Hunter: Shadow Trap 680238 `count_stun` and `count_dot` (681179 and 681177 on seven enemies inside the stun
radius, exactly 5 in total; provisional until the owner reads the tooltip's count, claim 117.1).
