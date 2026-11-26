# Hit periods (`behaviour_metric_delta`, `kind: "hit_period"`, ADR 0552)

A cast's hits on the dummy are polled with game-time stamps; (last - first) / (n - 1) is judged with the
`cast_period` judge (its model's `kind` is `cast_period`) against `expected_ms` in the G-19 band (Soulfreeze
801724's ticks).

`setup_casts` (ADR 1120, absent by default): a list of `{"actor": "caster" | "dummy", "spell", "target": "caster" |
"dummy", "wait_ms"}` made for real after the control read and before the trigger, in order, each followed by its
wait; a caster cast gets its base mana (or flat cost) and a cooldown reset first, and its spell is learned at the
start. Use it when the period needs a state a real cast makes (Spirit Eclipse 811117 `eclipse_period`: a real Mirage
501136 makes five Spirits, and the dummy casts Detect Invisibility 132 so the invisible caster can target it).

`learn` (absent by default): spells learned at the start with the trigger, for a period a passive talent changes; a
second entry without it is the control (Dark Loa's Blessing 560545 `puppets_period` and `puppets_period_control`:
Shadow Puppets 501087 hits every 600 ms with the talent, 750 ms without).

`read_at_cast` (ADR 1282, absent by default): `true` reads the dummy's hits between the start stamp and the trigger
cast and gives that pair to the judge as its first read, for an effect that ticks at the cast instant (Fury Unleashed
555738 `strike_period`, Fury of the Illidari 561216 `assault_period`). The window must start at 0 and end between
2 x `expected_ms` + band and 3 x `expected_ms` - 2 x band (G-19), so it holds three ticks when the first lands at the
cast and two (unmeasured) when it lands one period late. The model carries `first_at_cast`: the first hit must
lie in (start, first poll], else the judge alerts, so a late first tick cannot pass when the clock overruns the window.
