# Second strike (`metric_delta` `second_strike`, ADR 1222)

`second_strike` is `{spell, present, wait_ms?}` on an entry with a `strike`, `spell` other than the strike's spell,
`wait_ms` 300 by default. After each trigger cast:

- in the treatment phase, the entry's metric is read once (`<spell> second_strike present`) and must equal `present`;
- the caster's dodge and parry are set to 0% (the `caster_avoidance` step before that cast is replaced);
- the striker casts `spell` at the caster and the scenario waits `wait_ms`, then the entry's own wait to its reading.

Right after the before reading and right after the after reading, the damage logs of `spell` (`spell_log_count`, the
striker as caster) are counted. A present read other than `present`, or a phase without exactly one landed second
strike (1 after the before phase, 2 in total after the after phase), makes the verdict `unmeasured`. Otherwise the verdict is
the plain `metric_delta` verdict, so a state the second strike did not consume alerts against an `expected` of 0.

Named points: `after_trigger_steps` (the read and the strike), `fixtures` (the avoidance and the log read), `verdict`.

Sun Cleric: Light of the Sun 704941 `parry_next` (Night Slaughter 23583, SPELL_ATTR0_NO_ACTIVE_DEFENSE, after a
Speed Slash 2118233 parried at 100%; ledger row 279).
