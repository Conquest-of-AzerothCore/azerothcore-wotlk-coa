# Fields sum (`metric_delta` `fields_sum`, ADR 0711)

`fields_sum` is the fields of a second read of the entry's own metric (for example another spell id), different from
`fields`. Right after each judged reading (before, after, expired) the scenario reads the metric with these fields,
labelled `<reading> sum part`, and the judge sees the sum of the two reads in place of the reading. A missing part
leaves the reading missing (the plain judge then alerts on the missing measurement). Absent, the scenario is unchanged.

Named point: `run_values(values, model)`, called by `metric_delta_options.option_run` before the plain judge of a
behaviour `metric_delta`; `fixtures` adds the reads.

Witch Hunter: Purity & Wickedness 680544 `one_helper` (Torchlight 503662 on one Purity stack: Holyflame 681415 plus
Shadowstrike 681524 damage count 0 without the talent, exactly 1 with it; owner ruling O-24).
