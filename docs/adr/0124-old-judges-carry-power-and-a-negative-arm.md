# 0124. Old judges carry power and a negative arm

- Status: accepted
- Date: 2026-11-11

## Context

The prototype review (prototype `score.md` §7, I8 with I6) found the old judges weaker than the prototype's proof
gate, which refused a verdict without power and required an arm without the effect:

- the count judge (`behaviour_count`, `behaviour_fixed_count`) compared with the shared delta margin
  `max(1, 0.5% of expected)`, so "strikes 2 additional enemies" passed with 1 enemy struck, and the scenarios
  offered exactly the stated number of extra dummies, so a server striking more read the same;
- `passive_delta` judges an integer stat with the same 1-point floor. Under about 20 points of expected delta the
  floor is wider than the 5% tolerated band: 6 of the 27 round 10 promotions to behaviour could not tell the stated
  value (Light's Chosen 301310 combat rating +4 for +4.8, Martial Paladin 705250 Agility +6 for +6.6, 705251 +13 for
  +13.2, Bells of Light 801204 Agility +3 for +3.96, 803842 Agility +7 for +7.92 and Intellect +1 for +1.92), and the
  Intellect row of 801204 rested on the pre-truncation `stat_exact` read while the integer stat stayed at 32
  (`SetStat(stat, int32(value))`, StatSystem.cpp:159).

The owner's fix order of 2026-11-11 asks for power and a negative arm in `hit_ratio`, the count judge and
`passive_delta`, and for these 7 rows to be demoted; `hit_ratio` is ADR 0125.

## Considered options

1. Demote the 7 rows by hand in the clause ledger. Rejected: the ledger holds labels, not evidence; evidence is
   computed from verdicts, and the next run would promote them again.
2. Turn the under-powered `passive_delta` verdicts into `insufficient_trials`. Rejected: a state read has no trials
   to add; the reading is conformant, it only cannot tell the stated value.
3. Judge counts exactly with one candidate beyond the stated number, and mark a `passive_delta` verdict that only the
   floor accepted as data conformant. Chosen.

## Decision

- Counts are compared exactly (`compare.exact_count_verdict`): one target too few or too many is an `alert`.
  `target_count` and `fixed_count` scenarios offer `expected + 1` candidates inside the radius
  (`behaviours.COUNT_HEADROOM`, model `headroom`). A matching count without such a candidate is
  `insufficient_trials`. `ally_heal_breadth` states every offered ally (`all_offered`), so its match is judged. The
  aura-spread scenario keeps one extra dummy (`SpreadCondemn` afflicts the next dummy on every hit,
  AscensionTemplar.cpp:227-255), so Holy Tempest 301339's match is `insufficient_trials` until a scenario can show a
  dummy staying clear. The before-learn phase stays the negative arm (`unmeasured` when an extra dummy was already hit).
- A `spell_damage_count` count scenario reads every dummy after every cast of the judged phase (model `per_cast`) and
  the judge takes the widest cast that hit the primary dummy (`compare.per_cast_count_verdict`): "ever hit" over five
  casts would count a target that moved between casts. With the extra dummy, Holy Cleave 573049 read [1, 2] per cast
  because each cast grants Oath: Holy Cleave 804903 (`Effect[0]` aura 107, `SPELLMOD_JUMP_TARGETS`, the tooltip's own
  "Your abilities strike $804903s1 additional nearby target"); its entry names `clear_auras` [804903], set to 0 before
  every cast.
- A conformant `passive_delta` verdict carries `detail['data_only']` with its reason when the metric's floor is wider
  than the 5% band of the expected delta and the reading is off the expected value (`compare.floor_only_reason`),
  and a `stat_exact` verdict always does. `coverage.verdict_evidence` counts such a verdict as data. An exact reading
  (expertise +5 for +5, run speed 0.2 for 0.2) keeps its evidence. The negative arm is the before-learn read; a delta
  of 0 against a nonzero expected delta stays an alert.

## Consequences

- Scarlet Judicator 525024, Justice 712437 and Holy Cleave 573049 scenarios gain one dummy; Holy Tempest 301339 drops
  from behaviour to unproven; Libram of Grace 801463 and Chakra of Light 803159 are judged exactly.
- The 7 rows above are data conformant; any other integer state read that only the floor accepted is data too (for
  example Sturdy 681009 maximum energy +4 for +5, Pious 706431 stats).
- Old manifests without `headroom` give `insufficient_trials` on a matching count: rerun them.
