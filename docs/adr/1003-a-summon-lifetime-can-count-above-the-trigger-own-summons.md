# 1003. A summon lifetime can count above the trigger's own summons

- Status: accepted
- Date: 2026-11-17
- Builds on: ADR 0544, ADR 0546

## Context

Kennel Master 706365 / 707891 ("Casting Unleash The Hounds now has a $h% chance to summon an additional Lesser Shadow
Hound for $707890d.") adds one Lesser Shadow Hound 50224 for 15000 ms (707890 DurationIndex 8) to a cast of Unleash the
Hounds 807933, which itself summons 2 hounds of the same entry for 20000 ms (DurationIndex 18). The `summon_lifetime`
kind needs a control count of 0 and an owned count of 0 or 1, so it cannot read the extra hound. The roll is hard-coded
(`roll_chance_i`, `AscensionWitchHunterAbilities.cpp:647-650`), so the kind's SPELLMOD_CHANCE_OF_SUCCESS forcing
modifier does not reach it. Design from the nf-a stop (Witch Hunter not-final pass), approved by mentor D-465
(category A, judging of existing entries unchanged).

## Decision

Opt-in `summon_lifetime` fields `baseline_count` and `baseline_ms`, set together, `baseline_ms` beyond the end window:

- the control count must equal `baseline_count` (else `alert`, as a control summon is today); the control waits until
  `baseline_ms` + 1000 ms after its cast and reads the count 0 before the talent is learned;
- the treatment reads the count 0 right before its cast; that read, stamped by the cast's game-time mark, opens the spawn
  window;
- the talent's creature is present while the count reads `baseline_count + 1` and gone once it reads `baseline_count`;
- a baseline left after its expiry, a creature before the cast, or an end-window count other than those two is
  `unmeasured`;
- an end window that holds `baseline_count + 1` throughout (or `baseline_count` from its first poll) bounds the lifetime
  at that window edge, so a lifetime past the window (the 20000 ms baseline, or 10% off the stated value when the window
  reaches 10% from it) alerts instead of staying `unmeasured`.

`roll_source` (text, only with a baseline) names the server line that makes the roll, cited in the contract. The pooled
judge (ADR 0546) leaves out a part whose spawn window never exceeds the baseline. Provisional number, renumbered at merge
(14.4).

## Consequences

- Entries without the fields generate byte-identical scenarios and keep their judge.
- Seeded tests in `kinds/test_summon_lifetime.py` (`SummonLifetimeBaselineTests`, on a copy of the Necromancer fixture
  entry 807700 with the fields added): the scenario order, an `ok` reading above the baseline, alerting mutants (a
  creature living through the end window, a short one, a control with the extra creature), `unmeasured` broken
  baselines, pooled parts at the baseline left out, refused field combinations, and no `baseline` model without them.
- The Witch Hunter entries pool 27 parts at 25% and 11 at 50%: a pair with a run of no summoned part has probability
  2 x 0.75^27 = 8.5e-4 and 2 x 0.5^11 = 9.8e-4, below 0.1% (D-197). Each part lasts about 38 s of game time because the
  control waits out the baseline.
