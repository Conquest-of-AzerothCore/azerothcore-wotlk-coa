# Monotone (`metric_delta` `monotone`, ADR 0712)

`monotone` is `{"levels": [power, ...], "cumulative": true|false}` on an entry with `phase_power` (power type, control,
first treatment). After the after reading, the treatment phase (from the expiry wait to the after reading) is repeated
once per level with the phase power set to that level, each read labelled `<spell> <metric> level <power>`. The judge
replaces the plain before/after bands: the readings at the control, the first treatment and each level must rise
strictly; with `cumulative` each phase is its own increase of the metric (a cumulative total such as
`spell_damage_total`). A missing reading alerts. It states no amount: a direction-only claim (mentor ruling D-165).

Named point: `verdict(verdict, run, value)` (`metric_delta_options.option_verdict`); `fixtures` adds the phases.

Witch Hunter: Damnation 520217 `rage_monotone` (25, 50, 75 and 100 Rage, claim 77.1 "converting each point of Rage
into additional damage").
