# 1024. An opted-in use-time read proves its claim with its named arms

- Status: proposed
- Date: 2026-11-22
- Related: [ADR 1018](1018-a-scripted-crit-read-proves-a-crit-claim-with-its-partner-arms.md) and
  [ADR 1023](1023-a-critical-block-chance-read-proves-its-claim-with-the-partner-arms.md) (the partner gate),
  [ADR 0691](0691-a-spell-crit-read-proves-a-crit-claim-with-its-learned-contrast.md) (the learned contrast).
- Decided by: mentor D-138 (2).

## Context

`spell_cast_time_ms` and `spell_power_cost` are READBACK metrics (ADR 0120), so a Sun Cleric clause such as Sunbeams
807874 "Reduces the cast time of Radiant Cascade by $s1%." stays data. The probe calls the engine's own use-time
functions, `info->CalcCastTime(player)` and `info->CalcPowerCost(player, school)` (`CoAGameplayTest.cpp:5633, 5667`),
the functions the real cast path calls (`Spell.cpp:3639, 3606`); the `spell` argument the probe leaves out only reaches
`ApplySpellMod` bookkeeping. A learned contrast on one build is then a measured difference of that function, the shape
of ADR 0691 / 1018 / 1023. What the read cannot show is the consumption of a mod charge, so a "next cast" clause needs
the after-consumption arm.

Witch Hunter already counts two entries of each metric with its own evidence; a rule on the metric itself could move
its counts of record.

## Options

- The rows of ADR 1023 on the metrics (`CONTRAST_PROOF`, `STATE_PROMISES`, `PARTNERED_CONTRASTS`). Rejected: it applies
  to every existing entry, Witch Hunter's included.
- Keep the reads as data. Safe, but the Sun Cleric rows could never reach behaviour.
- An opt-in rule: the entry names its arms in a `metric_delta` option, and only a verdict carrying it is judged by the
  learned contrast and the partner gate.

## Decision

The third option.

- Option module `metric_delta_options/use_time_contrast.py`: the entry field is the list of the arm suffixes (own arm
  included) on the same spell; it is refused on another metric or without the learned contrast. The verdict detail
  carries the arm labels and the declared gain (`expected - before_expected`, which an `expected_gain` must equal).
  Its promise words are option rows: cast time `cast time|instant|casting time`, cost `cost|mana|free`.
- `coverage.py`: a verdict that carries the field needs the learned contrast and passes `use_time_partners_hold`:
  every named arm is among the row's verdicts as a conformant, learned, opted-in verdict of the same metric, one gain is
  non-zero, and one is zero unless the sentence fullmatches `PLAIN_USE_TIME_SENTENCE` ("Reduces the cast time of
  <Name> by $s1%."). `CONTRAST_PROOF`, `PARTNERED_CONTRASTS`, `STATE_PROMISES` and `conditional_text` are unchanged.
- An entry without the field keeps the READBACK path.

## Consequences

- Tests: `test_coverage.py` `UseTimeContrastPartnerTest` (both arms, plain sentence, one arm, zero arm alone, a named
  arm absent, an arm that did not opt in, condition contrast, unpromised clause, a zero gain under an unpromised
  sentence, partner of another metric, entry without the field, field on another metric) with two mutants (gate
  removed, opt-in row removed); `metric_delta_options/test_use_time_contrast.py` for the option.
- Templar, Necromancer and Witch Hunter use no entry with the field; their audits are unchanged (checked before and
  after) and their generated scenarios regenerate byte-identical.
- A cost clause in the plain form ("Reduces the mana cost of <Name> by $s1%.") still asks for a zero arm.
- Number provisional: shared ADRs are numbered at merge.
