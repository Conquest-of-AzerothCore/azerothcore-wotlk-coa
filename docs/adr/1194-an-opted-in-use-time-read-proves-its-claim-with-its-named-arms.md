# 1194. An opted-in use-time read proves its claim with its named arms

- Status: proposed
- Date: 2026-11-22
- Related: [ADR 1188](1188-a-scripted-crit-read-proves-a-crit-claim-with-its-partner-arms.md) and
  [ADR 1193](1193-a-critical-block-chance-read-proves-its-claim-with-the-partner-arms.md) (the partner gate),
  [ADR 0691](0691-a-spell-crit-read-proves-a-crit-claim-with-its-learned-contrast.md) (the learned contrast).
- Decided by: mentor D-138 (2).

## Context

`spell_cast_time_ms` and `spell_power_cost` are READBACK metrics (ADR 0120), so a Sun Cleric clause such as Sunbeams
807874 "Reduces the cast time of Radiant Cascade by $s1%." stays data. The probe calls the engine's own use-time
functions, `info->CalcCastTime(player)` and `info->CalcPowerCost(player, school)` (`CoAGameplayTest.cpp:5633, 5667`),
the functions the real cast path calls (`Spell.cpp:3639, 3606`); the `spell` argument the probe leaves out only changes
the charge accounting of `ApplySpellMod` and its Bloodmage (CLASS_SON_OF_ARUGAL) empowerment branch. A learned contrast on one build is then a measured difference of that function, the shape
of ADR 0691 / 1188 / 1193. What the read cannot show is the consumption of a mod charge, so a "next cast" clause needs
the after-consumption arm.

Witch Hunter already counts two entries of each metric with its own evidence; a rule on the metric itself could move
its counts of record.

## Options

- The rows of ADR 1193 on the metrics (`CONTRAST_PROOF`, `STATE_PROMISES`, `PARTNERED_CONTRASTS`). Rejected: it applies
  to every existing entry, Witch Hunter's included.
- Keep the reads as data. Safe, but the Sun Cleric rows could never reach behaviour.
- An opt-in rule: the entry names its arms in a `metric_delta` option, and only a verdict carrying it is judged by the
  learned contrast and the partner gate.

## Decision

The third option.

- Option module `metric_delta_options/use_time_contrast.py`: the entry field is the list of the arm suffixes (own arm
  included) on the same spell; it is refused on another metric or without the learned contrast. The entry needs an
  `expected_gain`, so the judge compares the measured `after - before` with it (`metric_gain_verdict`, as ADR 1188
  does); an after floor (`after_at_least`), ceiling (`after_at_most`) or `expected_ratio` is refused, and so is a
  tolerance of half a non-zero gain or more. The verdict detail carries the arm labels and the declared gain
  (`expected_gain`).
  Its promise words are option rows: cast time `cast time|instant|casting time`, cost `cost|mana|free`.
- `coverage.py`: a verdict that carries the field needs the learned contrast and passes `use_time_partners_hold`:
  every named arm is among the row's verdicts as a conformant, learned, opted-in verdict of the same metric whose judged
  gain (`expected`) equals its declared gain and whose measured gain lies in its band; every arm's half-band is below half
  the smallest non-zero gain, so a wide zero arm cannot fake the consumption; one gain is non-zero, and one is zero
  unless the sentence fullmatches `PLAIN_USE_TIME_SENTENCE` ("Reduces the cast time of
  <Name> by $s1%."). `CONTRAST_PROOF`, `PARTNERED_CONTRASTS`, `STATE_PROMISES` and `conditional_text` are unchanged,
  but `state_promises()` now returns the option's words for both metrics for every verdict: a future `CONTRAST_PROOF`
  row or STATE class for either metric would apply them to non-opted entries too.
- An entry without the field keeps the READBACK path.

## Consequences

- Tests: `test_coverage.py` `UseTimeContrastPartnerTest` (both arms, plain sentence, one arm, zero arm alone, a named
  arm absent, an arm that did not opt in, condition contrast, unpromised clause, a zero gain under an unpromised
  sentence, partner of another metric, entry without the field, field on another metric, a no-effect read in a wide
  band, a band of half the gain, a wide zero arm, a declared gain the verdict did not judge, a measured gain outside
  its band) with three mutants (gate removed, opt-in row removed, a gate trusting the declared gain);
  `metric_delta_options/test_use_time_contrast.py` for the option, including the refusals and the review probe
  (2500 -> 2500 stays unproven; with the refusals removed, a 400 ms band still stays data).
- Templar, Necromancer and Witch Hunter use no entry with the field; their audits are unchanged (checked before and
  after) and their generated scenarios regenerate byte-identical.
- A cost clause in the plain form ("Reduces the mana cost of <Name> by $s1%.") still asks for a zero arm: the exemption
  was written for the one plain sentence a ledger row needed (807874), and no Sun Cleric or Witch Hunter row has the
  plain cost form; extending it is a separate decision.
- The gate does not check that a zero arm reads the same `fields.spell` after consumption: a reviewer reads each named
  arm, as for the partner gates of ADR 1188 and 1193.
- Number provisional: shared ADRs are numbered at merge.
