# Relocate during wait (`metric_delta` `relocate_during_wait`, ADR 0993)

`relocate_during_wait` is `{"every_ms": N, "count": even, "dy": yards}`. Right after each cast of the entry's
`trigger_spell` by the caster (named point `after_trigger_steps`), the scenario makes `count` moves `every_ms` apart:
a harness `relocate` of `dy` yd along y, then `-dy`, alternating, so the caster ends where it started. `relocate`
applies the native position update of a client movement packet, so the movement interrupts run
(`Unit::UpdatePosition`, `RemoveAurasWithInterruptFlags`); `set_moving` only sets a flag and interrupts nothing. The
reading follows the last move by `wait_ms`. It adds no check; the metric is usually `cast_remaining_ms` of the
trigger channel. Absent, the scenario is unchanged.

Witch Hunter: Twilight Frenzy 805751 (the channel continues while the caster moves), with Witchbane 574320 as the
control that the same moves do interrupt a channel carrying the movement interrupt.

The module declares the evidence class of `cast_remaining_ms` (a state) and the tooltip words that promise it
(`move while active`) through `option_rows`, so the coverage audit can class a channel read.
