# Apply stamp (`metric_delta` `apply_stamp`, ADR 1067, provisional)

`apply_stamp` is `{"aura": A, "window": [LOW, HIGH], "source": text}` on an entry with `game_time` and a `strike`
that lands before the trigger cast. The after phase opens an encounter timeline (`encounter_start` on the striker's
entry) before its strikes. The harness timeline stamps every apply and refresh of `A` on the entry's `measure_actor`
(`OnAuraApply`) and the trigger cast in one game-time base. Right after the trigger cast the scenario reads the apply
count (`cast_count`) and then the game time (`cast_upper`). Right after the after reading it reads the game time
(`read_upper`), the apply count (`count`), the trigger cast stamp (`clock`) and the first apply stamp (`first`)
(`timeline_count`, `timeline_first_ms`; labels `<spell> apply_stamp <stamp>`).

The after reading is bracketed from the aura apply:

- at least `game_time after - cast_upper`, valid when no apply follows the trigger cast (`cast_count == count`);
- at most `read_upper - game_time cast + (clock - first)`.

The verdict keeps the metric delta's status when the bracket lies in `LOW..HIGH`, and turns `alert` when it leaves
the window. A missing or non-finite stamp, no apply stamped, or an apply after the trigger cast makes it
`unmeasured`. `source` cites the duration and the bound the window excludes; the contract quotes it. The `game_time`
windows still apply.

The encounter timeline makes the scenario exclusive in a simulated-clock batch (`encounter_start` is process
global). Python only, opt-in: harness metrics `encounter_start`, `timeline_count`, `timeline_first_ms` and
`game_time_ms` already exist.

Named points: `phase_steps` (the timeline), `after_trigger_steps` (the reads after the cast), `fixtures` (the reads
after the reading and the contract), `model`, `verdict`.

Sun Cleric: Stalwart 300355 `immunity_held` (window 3620..3990 ms) and `immunity_gone` (4010..4380 ms) on Stalwart
301342, `$301342d` = 4000 ms: they exclude 3600 ms and 4400 ms.
