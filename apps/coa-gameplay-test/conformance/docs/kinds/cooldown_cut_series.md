# Cooldown cut series (`behaviour_metric_delta`, `kind: "cooldown_cut_series"`, ADR 1026)

ADR 1026 is a shared ADR whose number is provisional and assigned at merge.

A percent cut of a running cooldown per tick of an aura and the tick period ("reduces the cooldown of Spirit Glaive by
20% every 1 sec"), read from the remaining cooldown itself. The spells of `learn` and of `casts` are learned. Each arm:

- makes the real `casts` in order (`spell`, `target` caster or dummy, `wait_ms` after the cast), one of them the
  `gated_spell` whose cooldown is read; `cast_power` is set before every cast;
- reads the remaining cooldown of `gated_spell` (`cooldown_ms`) and the game time (`game_time_ms`) `series.reads`
  times, every `series.step_ms` ms;
- cancels the auras of `clear_auras`, so an aura of one arm never ticks into the next.

The control arm runs before `talent` (default `spell`) is learned, the treatment after it. `pct_source` and
`period_source` (`[spell, effect]`) tie `expected_pct` to the effect's points and `expected_period_ms` to its
amplitude; generation refuses a mismatch.

For two reads a and b, the excess e = (before_a - after_b) - (time_b - time_a) is the cut of a tick between them
(exact up to the read jitter `jitter_ms`, default 20), whatever the tick's moment. The judges, with the G-19 band b:

- the control must keep |e| within the jitter: an e above both the jitter and 2% of the cooldown alerts (a cut
  without the talent); another excess is `unmeasured` (the two clocks disagree);
- `amount` (label `<spell> behaviour_metric_delta <label_suffix>`): every treatment pair with e above the jitter is a
  tick; its share lies in [(e - jitter) / before, (e + jitter + 1) / (before - elapsed - jitter)] (floor rounding).
  All inside `expected_pct` +- b is `ok`, any wholly outside alerts, else `unmeasured`;
- `period` (label `<label_suffix>_period`): the first and last ticks bracket the mean period; it must lie inside
  `expected_period_ms` +- b, and no gap between two ticks may lie wholly outside the band;
- fewer than `min_ticks` (default 3) ticks: none alerts, some are `unmeasured`.

The metric `cooldown_cut_series` is event class (`METRIC_EVIDENCE` of the module): a stamped series under a real aura
against a control series is behaviour evidence; a single `cooldown_ms` read stays data (ADR 0342).

Witch Doctor: Residual Energy 706543 (Lesser Shadow Avatar), Vol'jin's Blessing 706577 and Shadow Avatar 705943 on
Spirit Glaive 562719.
