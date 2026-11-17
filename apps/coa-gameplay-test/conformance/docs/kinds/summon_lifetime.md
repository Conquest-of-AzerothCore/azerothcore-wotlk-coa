# Summon lifetime (`behaviour_metric_delta`, `kind: "summon_lifetime"`, ADR 0544)

A proc that summons a timed creature is read for the creature's lifetime. A forcing fixture (mentor N-a1, as in
`forced_chance`) raises `talent`'s roll by 1000% for the scenario and is removed and read gone at the end. Control:
`trigger_spell` cast at the dummy before `talent` is learned, its aura removed `stop_ms` later, then the owned
`entry` count must read 0. Treatment: the same cast with `talent` learned; the owned `entry` count is polled every
25 ms with `game_time_ms` stamps in `spawn_window` and `end_window` (ms after the cast, nominal), the trigger aura
removed at `stop_ms` between them so one creature is summoned. The creature appears between the last empty and the
first present poll and is gone between the last present and the first empty poll; the bracketed lifetime is judged
against `expected_ms` in the G-19 band (`ok` inside, `alert` outside, `measured` across an edge); a window without
its edge or with more than one creature is `unmeasured`. Harvest Plague's zombies 705747 / 707880 (15000 ms) use
Harvest Plague 500968, stopped after its first tick. The talent's ProcChance x 11 must reach 100%: the schema caps the
mutant at +1000%.
`parts` (ADR 0546) pools one-tick parts for a talent whose forced roll stays below 100%: a part whose spawn window never
shows the creature is left out, every summoned part must pass, and at least one must summon (Unholy Erosion 807700,
33% per tick, 40 parts).
`baseline_count` and `baseline_ms` (ADR 1003, provisional; opt-in, set together) serve a trigger that summons the same
creature itself, for longer than the talent's creature lives (Kennel Master 706365 / 707891: Unleash the Hounds 807933
summons 2 Lesser Shadow Hounds 50224 for 20000 ms, the talent one more for 15000 ms). The control must read exactly
`baseline_count`; the scenario then waits until `baseline_ms` plus 1000 ms after the control cast and reads the count 0
before the talent is learned, and reads 0 again right before the treatment cast (that read and the cast's game-time stamp
open the spawn window). The talent's creature is present while the count reads `baseline_count + 1` and gone once it
reads `baseline_count`; any other count in the end window, a baseline left after its expiry or a creature before the cast
is `unmeasured`. An end window that reads `baseline_count + 1` throughout, or `baseline_count` from its first poll,
bounds the lifetime on one side only (at least the last poll, or at most the first poll, from the spawn edge): it
alerts when that bound lies wholly outside the band and is otherwise `unmeasured`, never `ok`. `roll_source` (only with a baseline)
names the server line that rolls the talent outside the forcing modifier, cited in the contract; such entries pool
`parts`.
