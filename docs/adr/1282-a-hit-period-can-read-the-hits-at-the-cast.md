# 1282. A hit period can read the hits at the cast

- Status: accepted (number 1282 assigned by the controller; mentor ruling D-103)
- Date: 2026-11-24
- Builds on: ADR 0552 (`hit_period`), ADR 0535 (the `cast_period` judge), ADR 1120

## Context

The `cast_period` judge needs at least three hits after a read of none (`kinds/cast_period.py`, the "first read of
none" rule). Fury Unleashed 555738 (555739 every $t1 = 1 sec) and Fury of the Illidari 561216 (808303 every $t1 =
0.5 sec) tick at the cast instant: with the window starting 1 ms after the cast, the first poll already reads one hit
and the judge alerts on the rule, not on the period (Felsworn prove-a2, both runs). A poll cannot come between the
cast step and its own first tick.

## Considered options

1. Change the judge to stamp the period from the second hit on. Rejected: a judge change, and it drops the first
   bracket.
2. Read the hits once more between the start stamp (already read just before the cast) and the cast, and give the
   judge that pair as its first read. The judge, its G-19 band and the evidence class stay as they are.

## Decision

Option 2. `hit_period` takes an optional `read_at_cast: true`. The scenario reads the dummy's hits of `hit_spell`
between the start game-time read and the trigger cast, and the model's `reads` begin with `[start label, that read]`,
so a tick at the cast lies in (start, first poll] and the existing rule holds on a real read of none.

A first tick one period late must not pass. With the option the window must start at 0 and end between
2 x `expected_ms` + band and 3 x `expected_ms` - 2 x band (G-19 band): it then holds three ticks when the first lands at
the cast and two when it lands one period late, which the judge reports as unmeasured (fewer than three hits).

The window bounds the nominal poll budget, not the game time the last poll reaches: a slow simulated clock can carry
the last poll past 3 x `expected_ms`, and three late ticks would then read a correct period (review fw-rbper I-1).
The option therefore also puts `first_at_cast: true` in the model, and the `cast_period` judge alerts unless the first
hit lies in (start, first poll]. Models without the key are judged as before.

## Consequences

- Opt-in: without the field (or with `false`) the steps, contract and model are unchanged; classes 15, 19 (with and
  without `--stack`), 23 and 27 generate byte-identical scenarios.
- Seeded tests: a tick at the cast every 1000 ms is ok; an 800 ms period alerts; a hit read before the cast alerts;
  a first tick one period late is not ok; a window that could hold a late third tick is refused; with polls every
  25 ms (the clock overruns the window) a first tick one period late alerts, a tick at the cast stays ok, and the same
  late run without `first_at_cast` (the mutant) reads ok.
- The period rests on three hits; a missed or avoided tick leaves two (unmeasured), never a false ok.
- Felsworn 555738 `strike_period` (555739 main-hand hits only; the off-hand 806097 of Felsworn ADR 0029 has its own
  spell id and is not counted) and 561216 `assault_period` use it.
