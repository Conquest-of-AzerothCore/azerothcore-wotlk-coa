# Hold power during the wait (`metric_delta` `hold_power_during_wait`, ADR 1207 addendum, provisional)

`hold_power_during_wait` is `{"power": type, "every_ms": N, "count": N}`, `every_ms` at least 100. Right after each
cast of the entry's `trigger_spell` (named point `after_trigger_steps`), the scenario makes `count` rounds of a wait of
`every_ms` and a `set_power` of that power type to `cast_power`, so a spell with a per-second power drain
(`ManaPerSecond`, drained by `Aura::Update` every 1000 ms, which removes the aura when the pool is below the
amount) is not ended early by the harness's single power fixture. The reading follows the last refill by `wait_ms`, so
the total wait is `count x every_ms + wait_ms`. It needs `cast_power`. The builder refuses it when the metric is a
power metric or the quote mentions mana, cost, resource, energy, rage, focus, runic, power or regeneration: a refill
would feed the measured thing. `fixtures` says so in the contract. It adds no check. Absent, the scenario is
unchanged.

Felsworn: Sargeras Embrace 800355 (ManaPerSecond 30 Energy, a 5500 ms channel).
