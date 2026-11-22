# Swing reset rate (`behaviour_metric_delta`, `kind: "swing_reset_rate"`, ADR 1017)

A talent's chance to reset another spell's cooldown on each landed auto-attack hit: the swing twin of
[`cooldown_reset_rate`](cooldown_reset_rate.md), whose clear-cooldown read and pooled judge it reuses unchanged.
`reset_spell` is learned; the caster auto-attacks the dummy for `control_ms` before `talent` is learned and for
`attack_ms` after, each phase ended by `stop_attack` and a 1000 ms settle before its reads. A reset is a
`SMSG_CLEAR_COOLDOWN` (0x1DE) whose first field is `reset_spell` (`server_packets` with `row`); trials are the caster's
damaging auto-attack hits of both hands (`melee_damage_count`: misses, dodges and parries are no trial). A control reset
in any part alerts; the treatment rate is judged as a proc rate (Wilson 99% interval inside the G-20 band of
`chance_pct`); fewer landed hits than the band needs are `insufficient_trials`.

Entry fields: `spell`, `name`, `quote`, `talent`, `reset_spell`, `chance_pct`, `control_ms`, `attack_ms`, optional
`parts` (identical pooled cases, as `cooldown_reset_rate`, ADR 0720) and `label_suffix` (default
`swing_reset_rate`). The case limit is the accelerated hour.

The entry is refused when its upper bound of swings, `parts` x the sum over the equipped melee weapons (main and off
hand with a swing speed) of `attack_ms // speed_ms`, is below the band's trials. The bound ignores haste and misses, so
passing it does not promise enough landed hits: the judge decides.

The scenario proves the rate on auto attacks only: a melee ability never rolls in this scenario.

Sun Cleric: Odyn's Vanguard 806699, resetting Glorious Execution 800626 at 20% (Valkyr set, two 2800 ms weapons).
