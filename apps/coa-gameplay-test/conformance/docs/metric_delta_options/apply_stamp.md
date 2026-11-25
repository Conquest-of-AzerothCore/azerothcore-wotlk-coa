# Apply stamp (`metric_delta` `apply_stamp`, ADR 1236, provisional)

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

**After the trigger** (ADR 1284, provisional). `"applied": "after_trigger"` with `"anchor": P` stamps an aura that
the trigger itself applies after its cast completes (a cast-time spell's hit, a projectile). It needs `game_time` but
no `strike`. The timeline stamps a cast when it goes off (`ALLSPELLHOOK_ON_CAST`), so the game-time reads around the
cast command do not bound it; and `timeline_first_ms` is an offset from the boss engage time
(`CoAGameplayTimeline.cpp:104`), not from the opening, so timeline stamps are compared only with each other. `P` is one
phase aura of the entry (a fixture set with stacks, not the stamped aura): right after `encounter_start` the option
removes it and sets it again, between two game-time reads (`open_lower` before the opening, `open_upper` after the
re-set), and stamps that apply (`anchor`, `anchor_count`). The apply lies `first - anchor` after the anchor, so the
after reading is bracketed:

- at least `game_time after - open_upper - (first - anchor)`;
- at most `read_upper - open_lower - (first - anchor)`.

The trial is void (`unmeasured`) when an apply precedes the trigger cast (`cast_count != 0`), when the apply count is
not exactly one (`count != 1`), when the apply precedes the completed cast (`first < clock`), when the anchor was not
applied exactly once (`anchor_count != 1`), or when the apply precedes the anchor. The anchor must leave the claim
unchanged: a fixture unrelated to the stamped aura, present again before the trigger cast. Without `applied` the
option is unchanged.

Named points: `phase_steps` (the timeline), `after_trigger_steps` (the reads after the cast), `fixtures` (the reads
after the reading and the contract), `model`, `verdict`.

Sun Cleric: Stalwart 300355 `immunity_held` (window 3620..3990 ms) and `immunity_gone` (4010..4380 ms) on Stalwart
301342, `$301342d` = 4000 ms: they exclude 3600 ms and 4400 ms.

Felsworn: Inner Demon 501298 `inner_dot_held` / `inner_dot_gone` (after the trigger) on Ruin 805748,
`$805748d` = 3000 ms.
