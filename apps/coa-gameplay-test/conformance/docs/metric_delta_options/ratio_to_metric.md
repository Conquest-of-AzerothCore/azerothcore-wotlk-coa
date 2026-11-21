# Ratio to metric (`metric_delta` `ratio_to_metric`, ADR 1030)

`ratio_to_metric` is `{"metric": name, "fields": {...}}`, a second metric of the measured unit. Right after each
judged reading (before, after, expired) the scenario reads that metric with these fields, labelled `<reading> ratio
base`, and the judge sees the reading divided by it in place of the reading. A missing or zero base leaves the reading
missing (the plain judge then alerts on the missing measurement). It cannot divide a summed reading (`fields_sum`,
`area_sum`, `ring_sum`) or divide a metric by itself. Absent, the scenario is unchanged.

Use it for a share of one value that another read of the same unit carries, when the tooltip states the share and
not the value: the share is then independent of the unit's stats.

Named point: `run_values(values, model)`, as `fields_sum`; `fixtures` adds the reads.

Witch Doctor: Spiritual Traditions 705911 `regen_casting` (`mana_regen_interrupted` over `mana_regen`, 0 without the
passive and 0.40 with it).

`increments` (ADR 1101, default false): both reads are running totals (event totals), so the after reading is the
increase of the reading over the after phase divided by the increase of the base over it; the before reading stays the
plain ratio. Witch Doctor: Voodoo Strings 705910 `strike_share`, Master of Concoctions 801690 `master_share`, Malefic
Arrow 707854 `arrow_heal`.
