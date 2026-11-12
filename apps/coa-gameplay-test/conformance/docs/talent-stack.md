# Talent stack (lever map)

The class file's `rotation` is a fixed sequence, `stack` the configurations that add talents to it one group at a time,
and `talent_modifiers` the talents whose tooltip states a change of one damage source:

| Field | Content |
|---|---|
| `rotation.learn` | the spells every configuration learns (Templar: Argent Blade 807268, Scourgebane 92111) |
| `rotation.set_power`, `auto_attack` | the power set before the rotation, and auto attacks from its start to its end |
| `rotation.cycle`, `cycles` | the steps of one cycle (a cast at `dummy`, a wait) and their repetitions |
| `rotation.drain_ms` | the wait after the last cycle, before the measurements |
| `rotation.sources`, `cast_sources` | the spells whose damage is measured, and those whose casts are counted |
| `stack[].name`, `talents` | a configuration and the talents it adds to every earlier one |
| `talent_modifiers` | `talent`, `name`, `tooltip`, `token`, `source` and its `source_text`, `question`; see below |

The Templar rotation, configurations and talents are those of the measurements of 2026-11-05
(`.agents/plans/class-spell-audit/stacking-scenarios/c0_base.json` to `c7_scarlet.json`): 120 cycles of a cast of Argent
Blade and a 1000 ms wait under auto attack, 100 Energy at the start, a 3000 ms drain, and the configurations c0 (no
talent), c1 Paladin Training 520009, c2 Divine Strikes 705255, c3 Light's Echo 520017 and 520883, c4 Warrior of Dawn
560648 and Scourge-Defense Training 520608, c5 Retribution 707391, c6 Legacy of the Silver Hand 806522 and Pure Focus
705253 and 707852, c7 Scarlet Training 301065, Scarlet Secrets 520812 and Martial Training 806525. The scenarios use
the package's base steps (weapon equipped and stats measured before the learns), so the steps come in a different
order from the files of 2026-11-05.

`stack_scenarios` writes `passes` scenarios per configuration, each named `... <config> pass <n> of <passes>`, that
learn the rotation spells and every talent of the configuration and the earlier ones, measure the health of `dummy`,
run the rotation, measure its health again after the drain, then per source the damage and hit count on `dummy` of
every hit and of the non-critical, unblocked hits (`spell_damage_*`, `melee_damage_*` for the auto attacks), and the
casts of the cast sources. Fewer than 2 passes give no interval and are refused. Each pass carries:

- `stack <config> dps` (`stack_dps`): the health the target lost per second of rotation (120 s), so that a source
  missing from `sources` still counts; the difference with the sum of the sources is shown as unattributed.
- `stack <config> source <spell>` (`stack_source`, 0 for the auto attacks): the damage of the source per second.
- `stack <config> talent_delta <talent> <source>` (`talent_delta`) for each `talent_modifiers` entry of a talent
  the configuration adds.

The comparison groups the passes of a configuration. `stack_dps` and `stack_source` are `measured`: the mean of the
passes and its 99% Student t interval (n − 1 degrees of freedom; with 5 passes the quantile is 4.604, not 2.576).
Missing passes are `insufficient_trials`; a source without a hit in any pass after failed casts of it is `unmeasured`
(R11). The rotation presses Argent Blade every second against its 5 s cooldown: in c0 and c1, 96 of its 120 casts per
pass fail with `SPELL_FAILED_NOT_READY` (67). The explanation counts the failed casts per spell and reason.

A `talent_delta` is the change of the mean non-critical, unblocked hit of the source between the configuration and
the previous one, in percent: the ratio of the means of the per-pass hit means, with a 99% interval from the Welch
degrees of freedom and the variance of each mean (delta method). Failed casts lower the hits, not the hit mean. The
expectation comes from the entry:

- `status` (`unmodelled`, `ambiguous_tooltip`) and `reason`: a talent whose change of the source has no fixed amount
  (Divine Strikes: stacks over time; Scourge-Defense Training: the casts after a Warrior of Dawn proc; Martial Training:
  Scarlet Hammer appears only with it) or whose text is unclear (Legacy of the Silver Hand: critical damage of the
  whole hit or of its bonus). Such a delta is never `ok`; an `ambiguous_tooltip` entry has a `question` for players.
- otherwise `claim` (the words of the tooltip) and `dbc` (the effect fields, checked against the client DBC by the
  tests) cite the effect of the talent whose `EffectSpellClassMask` (three words per effect) meets the
  `SpellFamilyFlags` of the source, in the same `SpellFamilyName`; the `token`, read with `read_tooltip`, must be that
  effect's value. The rule is `ratio` only for aura 108 (`SPELL_AURA_ADD_PCT_MODIFIER`) with misc 0
  (`SPELLMOD_DAMAGE`): the tooltip "Increases the damage of <source> by $s1%" and a percent modifier of the spell's
  damage give an expected ratio of hits of 1 + $s1/100. Another aura (Martial Training: aura 107, a flat modifier)
  or a token of another effect is `unmodelled`.

Interactions are not absorbed. A change of the same source by another talent the configuration adds makes the delta
`unmodelled`; a change by an earlier talent whose amount is not a stated percent makes it `ambiguous_tooltip`, since
no text says how the two combine. Neither the tooltip nor the DBC says how the bonus composes with the other percents
of the hit: the damage modifiers of the known auras that apply to the source's school (887007 effect 0, aura 341,
-20%; aura 341 and aura 108 are different mechanisms, not a stated composition) and the stated percents of earlier
talents on the same source (rulings R12, R14). When there are any, the delta has two readings, judged like the proc
readings: `multiplies` (the bonus scales the damage of the previous configuration, the other percents included, so they
cancel in the ratio) and `adds` (the bonus adds to the other percents, 100 × b / (100 + Σ others)). Agreeing readings
give their verdict; disagreeing readings are `ambiguous_tooltip` with both expected values and the measurement, unless
the class file's `log_queries[label]` records that the Ascension logs were consulted and said nothing (ADR 0044's
owner fallback, below) and the server applies one of the two readings, which then settles `ok`. A known aura present
in some passes only makes the delta `unmodelled`. The integer steps
of a hit (truncation after a modifier, armor) are not modelled here: each moves a hit by under one point, about 0.1%
of the 1014 measured Argent Blade hit. The bonus is read again with the measured stats: a changed value is an alert.
Fewer passes than generated in either configuration are `insufficient_trials`; no hit of the source in either
configuration is `unmeasured`. The bonus is judged on the owner's band of 2026-11-11 (ADR 0125, `bonus.py`): each
reading passes when the measured bonus lies within the larger of 5% of it and 2 points ("+20%" passes from +18% to
+22%), so two readings inside one band are both conformant. Before that, a 99% interval whose half-width is above
half the band of the stated bonus, or that holds 0, is `insufficient_trials` even when it holds the bonus; the
explanation and `detail.trials_needed` give the passes that would meet it, the current passes times
(half-width / limit)², from the observed variance at the same t quantile. A judged delta states the bonus range it
excludes (`detail.excluded`, stated bonus -+ (band + half-width)); `low` and `high` stay the Welch interval that
`levers.md` lists.

`levers(verdicts)` gives one `Lever` per configuration in stack order: the DPS mean and interval, its change in percent
from the previous configuration, the DPS of each source and the tooltip bonus of the configuration's single judged
talent delta (`None` otherwise). `levers.md` holds the configurations, the DPS per source and its change, the talent
deltas, the known and probe auras with the runs that measured them, and every pass value. A configuration's DPS change
is marked decisive only when the 99% Welch interval of the ratio of its passes to the previous configuration's
excludes 0 and its half-width is at most 1% of the ratio; otherwise the column says why it is not (a configuration
whose DPS mean is not above 0 has no ratio and is never decisive), and the percent is
no result.

Measured on 2026-11-05 on the worktree server, which does not yet hold PR #11297 (Argent Blade's flat bonus after its
percent), with 5 passes per configuration (stamp `20261105-204050`, simulated clock, gameplay stage 32.5 s for 40
passes of 1.3 s each):

| Config | DPS | 99% interval | Change (not decisive) | Argent Blade | Scourgebane | Retribution | Scarlet Hammer |
|---|---|---|---|---|---|---|---|
| c0 | 298.1 | 289.6 to 306.5 | | 202.8 | 76.2 | 0 | 0 |
| c1 | 333.2 | 328.8 to 337.6 | +11.8% | 244.0 | 70.2 | 0 | 0 |
| c2 | 436.0 | 426.3 to 445.8 | +30.9% | 346.2 | 70.8 | 0 | 0 |
| c3 | 538.8 | 449.6 to 628.0 | +23.6% | 435.4 | 84.4 | 0 | 0 |
| c4 | 701.2 | 568.6 to 833.8 | +30.1% | 587.2 | 95.0 | 0 | 0 |
| c5 | 776.0 | 426.8 to 1125.1 | +10.7% | 605.9 | 90.6 | 60.4 | 0 |
| c6 | 926.7 | 575.8 to 1277.7 | +19.4% | 672.1 | 169.3 | 66.4 | 0 |
| c7 | 1027.2 | 664.5 to 1389.9 | +10.8% | 669.8 | 230.3 | 79.9 | 28.2 |

The auto attacks dealt 19.0 per second in every configuration and nothing was unattributed. Paladin Training raised
the Argent Blade hit by 20.27% (99% interval 19.51 to 21.03, half-width 0.64% of the ratio) against its $s1 of 20:
`multiplies` (20%) is `ok` and `adds` with 887007's -20% (25%) an alert, so the verdict is `ambiguous_tooltip`; a run
of c0 and c1 alone (stamp `20261105-203950`) gave 20.00% (19.22 to 20.78), the same verdict. No DPS change is
decisive: the intervals of c1 to c4 exclude 0 but their half-widths are 2.58%, 2.03%, 16.31% and 18.41% of the
ratio, and the intervals of c5 to c7 hold 0. The procs spread the passes of a configuration (c5: 615 to 1031 per
second).

### Owner fallback for a two-reading ambiguous tooltip

`compare.py`'s `owner_fallback(statuses, log_query)` is the one place that decides what a disagreement between a
tooltip's two permitted readings becomes, used by both `judge_talent_delta` (talent stack deltas, above) and
`judge_readings` (passive deltas whose metric has a `composition`, "[Passive effects](passive-effects.md#passive-effects)"). The rule
(ADR 0044, the owner's 2026-11-09 ruling generalised): a tooltip that permits two readings and whose server
measurement matches exactly one of them is `ambiguous_tooltip` until the class file records, in a top-level
`log_queries` dict keyed by the verdict's `label`, that the Ascension combat logs (`~/Projects/coa-log-history`,
never committed) were queried for the ambiguity and found nothing; once recorded, the verdict is `ok`, naming the
reading the server applies and the log query in its explanation. It is still `ambiguous_tooltip` without a recorded
`log_queries` entry (the status quo for every entry today: the dict is empty in `classes/templar.json`), and it is
`alert`, not `ambiguous_tooltip`, when a recorded query exists but the server's measurement matches neither reading
(unreachable with today's two-valued `ok`/`alert` status domain, since two disagreeing readings always include one
`ok` reading by construction, but kept as an explicit branch for a future check with three or more readings). A
`log_queries` entry only records that a query was made and drew a blank; a query that actually finds a reading in
the logs is an owner ruling settled in prose (like Light's Echo 520017/520883, "no self-chain, current behaviour"),
not a `log_queries` entry.
