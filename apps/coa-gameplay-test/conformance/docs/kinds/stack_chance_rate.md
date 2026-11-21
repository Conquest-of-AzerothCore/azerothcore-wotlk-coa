# Stack chance rate (`behaviour_metric_delta`, `kind: "stack_chance_rate"`, ADR 0662)

ADR 0662 is a shared draft whose number is provisional and assigned at merge; its class half is Witch Doctor ADR 0001.

A chance that grows with the stacks of an aura on the caster ("Each active Spirit gives you a 15% chance when you
cast Malefic Arrow to generate an additional Spirit."), rolled by a script (`roll_chance_i`) that the `forced_roll`
fixture (SPELLMOD_CHANCE_OF_SUCCESS) does not reach. `trigger_spell` is cast at the dummy, `cast_wait_ms` apart, after
the spells of `learn` (the trigger is always learned). Before every cast, harness `set_aura` sets `stack_aura` to the
arm's stacks: a precondition fixture (G-21 point 6, guide 3.4), named in the verdict, because the subject is the event
the talent produces, not the stacks. The class ADR states why a real stack costs more than the fixture.

The arms run in this order in every part:
- `unlearned`: `unlearned_trials` casts at the largest arm's stacks before `talent` (default `spell`) is learned;
- `control`: `control_trials` casts at 0 stacks after the learn;
- one arm per `arms` item (`stacks`, `trials`), each `stacks` between 1 and the aura's `StackAmount`.

Each arm reads the cumulative `spell_cast_count` of `trial_spell` (default `trigger_spell`) and of `event_spell` at its
start and end. An arm's trials are the counted casts of `trial_spell`; its events are the casts of `event_spell` less
`event_offset` per trial (0 by default; 1 when `event_spell` is the trigger itself and the trials are counted by a
spell each cast grants once). Casts the server refused are not trials, so no refusal biases the rate.

The judge (`stack_chance_judgement`):
- Controls: any event in either control alerts, and fewer than 50 control casts over the parts is
  `insufficient_trials`. Each control states the rate it excludes at 99%.
- Treatment arms: an arm of N stacks is judged on its total chance, N times `chance_pct` ("5 Spirits x 15%" is 75%),
  never divided by N. Its 99% interval must lie inside the G-19 band of that total, the larger of 5% of it and 2
  points (75% passes from 71.25% to 78.75%; ADR 0646 judges inside the band). An interval that holds the total but
  is not inside the band is `measured` (G-20: effect present, interval stated, not final).
- Interval: Wilson on the pooled count below 10 parts, the between-part t interval from 10 parts (ADR 0647,
  `compare.between_part_judgement`).
- The worst arm sets the status and the verdict's measured, expected and interval values; every arm's total, band
  and interval are in `detail.arms`. `contrast: learned` is stamped when both controls held.

Sizing (flip-proof, mentor M-14 and M-14a, ADR 0662): an arm of total chance p needs
n >= p(1 - p) x ((z_99 + z_flip) / b)^2 casts over its `parts` (`arm_trials_needed`), where b is `procs.rate_band(p)`
itself, the half-width the judge accepts (`compare.banded_rate`: expected plus or minus `rate_band`), z_99 = 2.576
and z_flip = 3.719 (`Z_FLIP`, one-sided 1e-4); from 10 parts the Student t quantile with parts - 1 degrees of freedom
replaces z_99. At the stated chance the arm's 99% interval then crosses each band edge with probability at most 1e-4
(2e-4 for both edges), so a correct claim does not flip between `ok` and `measured` across runs (the Loa Spirits flip
of the Witch Doctor proof `prove-c2r`). Below 10 parts 75% needs 5,284 casts, 60% 10,568 and 5% 4,706; at 13 parts
(t 3.055, 12 degrees of freedom) 5% needs 5,449. An entry with fewer casts over its `parts` is refused, unless
`pilot` is true (300 casts per arm, G-20 step 1, at best `measured`). An arm whose total reaches 100% is refused.
`parts` pool identical scenarios through `POOLED_JUDGE`. Each part uses the accelerated cap (one hour of game time,
ADR 0139) and at most 10,000 steps. G-20 step 3 applies per claim: when one counted pair of the sized entry would take
more than 90 minutes of wall time on the simulated clock, the claim keeps the pilot's `measured` interval and the cast
count the band needs (status 5). The class ADR states the game time, the acceleration it assumes and the wall time.

Two arms of different stacks separate a per-stack chance from a flat one: a flat 75% at 4 Spirits reads 75% against
60% plus or minus 3 points. `cast_power` sets the trigger's power before each cast (required for a costed trigger);
its cooldown is reset before each cast when it has one; `cast_wait_ms` must cover the global cooldown and the cast
time. `dummy_distance` (yd, at most 100) places the dummy; a trigger that uses the ranged slot must name it, because
at the default distance the core refuses every cast as too close (`SPELL_FAILED_TOO_CLOSE`, Spell.cpp:7355-7359), and
a run without it would count no trial at all.

Witch Doctor (Witch Doctor ADR 0001): Spirit Hunting 707504 (Malefic Arrow 801674, one extra Spirit 561136 at 15% per
Spirit, arms of 5 and 4 Spirits) and Loa Spirits 705843 (Reclamation 806288 cast an additional time at 5% per Spirit,
arms of 1 and 2 Spirits, trials counted by the Spirit each Reclamation grants, `event_offset` 1).

`streams` and `isolation` work as in `flat_chance_rate` (its Streams section; the stream helpers live in this
module): each arm's `trials`, `control_trials` and `unlearned_trials` are per stream and per part, the arm reads
are one group per stream, summed per part, and the crossing reads cover the trigger and the spells it triggers.
Witch Doctor: 8 streams for both entries, each caster 15 yd from its dummy and facing it (Malefic Arrow and
Reclamation need the target in front, FacingCasterFlags 1).
