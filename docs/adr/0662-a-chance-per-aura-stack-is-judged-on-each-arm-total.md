# 0662. A chance per aura stack is judged on each arm's total

- Status: proposed (shared ADR draft; the number is provisional, assigned at merge)
- Date: 2026-11-15
- Class half: [Witch Doctor ADR 0001][class-half]

## Context

Some talents roll a chance that grows with the stacks of an aura on the caster, through a script roll
(`roll_chance_i(count * chance)`) that the `forced_roll` fixture (SPELLMOD_CHANCE_OF_SUCCESS) does not reach. No
existing kind measures a rate that depends on a stack count; `cooldown_reset_rate` (ADR 0603) is the closest, with
one learned arm and one flat chance. The events are casts the server makes (an extra aura grant, a triggered recast),
so `spell_cast_count` (`ProcCounter::RecordCast`, which counts triggered casts too) counts them without a harness
change.

The G-19 band (ADR 0125) is the larger of 5% of the value and 2 points, and G-20 forbids widening it. The first draft
divided each arm's interval by its stacks and judged it against the band of the per-stack chance. For a 5% chance
per stack at 5 stacks, the 2-point floor per stack then accepts a total of 15% to 35% against 25%, about 40%
relative on the measured quantity. The mentor ruled on 2026-11-15 (cycle 2, M-1) that the band applies to the
measured total.

The first sizing gave each arm `procs.band_trials_needed(total)` casts, which puts the 99% half-width at half the
band. At the stated chance such an arm still leaves the band in about 1% to 5% of runs, and a repeated run then turns
`ok` into `measured` by chance. The Witch Doctor proof `prove-c2r` showed it on Loa Spirits 705843: run 1 `ok` at
4.85%, run 2 `measured` at 5.86% with the 99% upper bound 0.0703 just above the band's 0.0700, pooled 338 in 6,314
(5.35%, consistent with 5%). Guide 3.5 needs a negligible residual failure probability, and rerunning until a claim
passes is not allowed. The mentor ruled on 2026-11-15 (cycle 2, M-14) that every treatment arm is sized flip-proof,
and clarified (M-14a) that the margin b is the band half-width the judge accepts, not half of it.

## Options

1. Divide each arm's interval by its stacks and judge it against the band of the per-stack chance. Rejected (M-1): it
   multiplies the band by the stack count on the quantity actually measured.
2. One arm at the top stack count, judged on its total. Rejected: a flat chance equal to that total passes.
3. Two or more arms of different stack counts, each judged on its own total (stacks times the per-stack chance) with
   the G-19 band of that total. Chosen.
4. Real stacks from the class's own generator instead of harness `set_aura`. Allowed by this ADR, not required: the
   class ADR compares the cost (guide 3.4).

## Decision

The contributor-owned kind `stack_chance_rate` (`CONF/kinds/stack_chance_rate.py`, ADR 0581;
[kind page](../../apps/coa-gameplay-test/conformance/docs/kinds/stack_chance_rate.md)):
- Judge: each treatment arm's events over its trials, against the total `stacks x chance_pct`, with the G-19 band of
  that total and the inside-the-band rule of ADR 0646 (`compare.banded_rate`). The interval is Wilson on the pooled
  count below 10 parts and the between-part t interval from 10 parts (ADR 0647, `compare.between_part_judgement`).
  An interval that holds the total but is not inside its band is `measured`, not final (G-20).
- Sizing (M-14 and M-14a, flip-proof): an arm of total chance p needs n >= p(1 - p) x ((z_99 + z_flip) / b)^2 casts
  over its parts, with b = `procs.rate_band(p)`, the half-width the judge accepts (`compare.banded_rate`: expected
  plus or minus `rate_band`), z_99 = 2.576 (two-sided 99%) and z_flip = 3.719 (one-sided 1e-4,
  `NormalDist().inv_cdf(1 - 1e-4)`). From 10 parts the Student t quantile with parts - 1 degrees of freedom replaces
  z_99 (z_flip stays normal). At the stated chance the arm's 99% interval then crosses each band edge with
  probability at most 1e-4, both edges together at most 2e-4, so a correct claim stays `ok` on a repeated run.
  Generation refuses an arm below it. A `pilot` entry (300 casts per arm) is G-20 step 1, unchanged, and reads
  `measured` at best. G-20 step 3 applies per claim: when one counted pair of the sized entry would take more than
  90 minutes of wall time on the simulated clock, the claim stays `measured` with its interval and the cast count
  the band needs. The class ADR computes that wall time.
- Controls: 0 stacks with the talent known and the top stack count before it is learned; any event alerts, and each
  needs at least 50 casts over the parts.
- Fixture rule: the stacking aura may be set by harness `set_aura` before every cast only as a precondition fixture
  (G-21 point 6): the claim's subject is the event, the verdict names the fixture, and the class ADR states why a real
  stack costs more (guide 3.4). A claim delivered through auras that the stacking aura only synchronises keeps real
  stacks.

## Consequences

- A flat chance alerts on the lower arm, and a per-stack chance whose total leaves the band alerts even when the
  per-stack reading of option 1 would have passed (the tests carry both mutants).
- Arms with a large total are cheap and arms with a total near 50% are dear: at 15% per stack, below 10 parts,
  5 stacks (75%) need 5,284 casts, 4 stacks (60%) 10,568, 1 stack 12,632 and 2 stacks 20,805; 5% needs 4,706.
  From 10 parts the t quantile raises these (5% needs 5,449 over 13 parts, t 3.055 with 12 degrees of freedom). The
  class ADR picks the arms.
- The flip-proof size is about 1.5 times the first sizing (((2.576 + 3.719) / 2.576)^2 / 4 = 1.49; 75% from 3,540 to
  5,284 casts): somewhat more parts per claim and more wall time. In exchange a correct chance flips between `ok`
  and `measured` across runs with probability at most 2e-4 per arm (1e-4 per band edge), and a flip in a proof is
  evidence of a real departure, not of sampling.
- The kind needs no harness change: `set_aura`, `set_power`, `reset_cooldown`, `cast` and `spell_cast_count` exist.
- Tests: `kinds/test_stack_chance_rate.py` builds a minimal inline class-file dict (ADR 0580 forbids reading a live
  class file; no fixture copy is needed).
- The index line in `CONF/docs/behaviour-scenarios.md` is owner-owned and added at merge.

[class-half]: conformance/witch-doctor/0001-spirit-chance-claims-run-set-spirits-in-two-stack-arms.md
