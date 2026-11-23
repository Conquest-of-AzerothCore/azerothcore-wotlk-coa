# Relog before read (`metric_delta` `relog_before_read`, ADR 1133)

`relog_before_read` is `{"before_offline_s": s, "after_offline_s": s}`, two offline times on either side of 15
minutes. Right before each judged reading the scenario snapshots the read, stamps the game time, saves and logs the
caster out with its stored logout time moved back by the phase's offline time (the harness `relog`
`offline_seconds`), logs it in again and stamps the game time again; the reading is the read after the login divided
by the snapshot before the logout (`ratio_to`). The verdict adds the relog's own game time to each stated offline
time and is `unmeasured` when the two arms then do not straddle 900 s. It needs both phases cast, no expiry read and
no other ratio or sum. Absent, the scenario is unchanged.

Named points: `fixtures` (the snapshot, stamps and relog), `model` and `verdict` (the straddle guard).

Witch Doctor: Brew Stew 807056 `logout_expiry` (the conjured Black Lotus Bisque 339008 kept after 870 s offline and
gone after 930 s, the stock 15-minute conjured-item rule at login).
