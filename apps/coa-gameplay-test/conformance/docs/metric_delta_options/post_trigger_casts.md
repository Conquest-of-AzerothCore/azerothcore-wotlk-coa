# Post-trigger casts (`metric_delta` `post_trigger_casts`, ADR 1203, provisional)

`post_trigger_casts` is `{"spell": ID, "count": 1..20, "gap_ms": >= 1600, "health_pct": 1..99}` (`gap_ms` and
`health_pct` optional; default gap 1600 ms, the global cooldown). Right after the trigger cast of every phase that
casts it (named point `after_trigger_steps`), the caster casts `spell` on itself `count` times `gap_ms` apart, each
after a cooldown reset and a power refill, with its health set to `health_pct` of the fixture first when given, so a
heal is effective. The reading follows the last cast by `wait_ms`. A phase that does not cast the trigger
(`cast_in_before` false) makes no post casts. It adds no check. Absent, the scenario is unchanged. Refused with a
`strike`, which uses the same point.

Sun Cleric: Pendant of the Sun 680630, "refreshing ... all charges of Dawn". Dawn state aura 807440 has ProcCharges
10 (Spell.dbc). Two Illumination heals in both phases, then the trigger, then nine more heals: with Pendant (refresh
to 10) the aura survives with 1 charge; the control entry (trigger Illumination, eight more heals, 11 heals in all)
exhausts the 10 charges at the 10th heal and the aura is gone.
