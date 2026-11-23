# Friendly creatures (`metric_delta` `friendly_creatures`, ADR 1265)

`friendly_creatures` is `{"entry": id, "distances": [yd, ...], "faction": id}` (1 to 12 distances, faction default 35,
friendly to the reference player). It adds creatures `friend1`, `friend2`, ... of that entry and faction at those
distances from the caster, outside the caster's party: precondition fixtures for a claim about every ally rather than
party members. The entry's metric must be `aura`; each judged reading (before, after, expired) is also read on every
friendly creature, labelled `<reading> friendN`, and the judge sees the sum of the measured unit's reading and the
creatures' readings. A missing part leaves the reading missing. Refused with `area_dummies`, `area_sum` or
`fields_sum`. Absent, the scenario is unchanged.

Named points: `check`, `fixtures`, `model`, `run_values`.

Felsworn: Taskmaster's Army 800220 `all_allies` (Infernal Whipcrack 805243 reaches ten friendly creatures beyond its
8-ally cap, entry 631 of the heal_sum fixture, ADR 1118).
