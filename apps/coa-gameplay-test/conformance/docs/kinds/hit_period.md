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
