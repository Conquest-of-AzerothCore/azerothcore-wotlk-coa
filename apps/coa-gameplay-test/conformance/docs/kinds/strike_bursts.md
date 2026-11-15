# Strike bursts (`behaviour_metric_delta`, `kind: "strike_bursts"`, ADR 0383)

A minion's scripted strikes after a Command: `command` is cast at the dummy (`distance` yd away) once with no minion
(the control: no hit), then `spell` raises a creature `entry`; each cycle casts `command`, reads the minion's hits 25 ms
before and after the strike tick (`burst_delay_ms`, 500), and casts the two `stances` (Pacify, then another) so the
minion stops. `arms` (`name`, `health_pct` falling from arm to arm, `cycles`, `low`, `high`) set the dummy's health;
every per-cycle count must lie in `low`..`high` and both ends must be seen. Raise: Skeletal Rogue 500969: 40
Commands at 37% read 2 to 5, 10 at 33% read 5.
