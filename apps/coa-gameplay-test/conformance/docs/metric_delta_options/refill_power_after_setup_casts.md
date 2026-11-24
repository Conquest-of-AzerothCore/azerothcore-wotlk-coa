# Refill power after setup casts (`metric_delta` `refill_power_after_setup_casts`, ADR 1207 addendum, provisional)

`refill_power_after_setup_casts` is `{"power": type}` or absent. After every setup cast (and its `setup_wait_ms`) the
caster's power of that type is set to `cast_power` with the existing `set_power` step, through the named point
`setup_cast_steps`, so a chain of setup casts that each cost a share of the pool is not refused for lack of power. It
needs `cast_power` and `setup_casts`. The builder refuses it when the metric is a power metric or the quote mentions
mana, cost, resource, energy, rage, focus, runic, power or regeneration: a refill would feed the measured thing.
`fixtures` says so in the contract. It adds no check. Absent, the scenario is unchanged.

Sun Cleric: Learning Light 300360 "or 3 casts". Illumination 500143 costs 30% of the mana pool (Spell.dbc
ManaCostPercentage 30); Dawn, the entering cast and three consuming casts need four of them.
