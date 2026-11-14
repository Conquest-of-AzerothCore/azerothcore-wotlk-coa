# 0646. A banded rate passes inside its band without the exact chance

- Status: accepted
- Date: 2026-11-14
- Amends: ADR 0346 (proc chances are proven to the band)

## Context

`banded_rate` (compare.py) judged a `band` proc rate, and every `cooldown_reset_rate` verdict, `ok` only when the
Wilson 99% interval held the stated chance and also lay inside the G-19/G-20 band (5% of the chance, at least 2
points). The mentor ruled on 2026-11-14 (00:38, 00:58) that a proc rate counts when its 99% interval sits inside the
band; holding the exact value is not required, as ADR 0571 already decided for the amount band of 138.0. Two
Necromancer claims had one run each that the rule counts and the judge alerted: 216.0 Harvest Plague 707880
(c11 run 2 [0.4013, 0.4176] in 0.38-0.42) and 77.0 503740 (c12 run 2 [0.1350, 0.1495] in 0.13-0.17).

## Options

1. Judge a banded rate by the band only: inside `ok`, otherwise as before.
2. Keep the exact-value condition and enlarge the sample until the interval holds it: no statistical reason, the band
   is the tolerance the rule states.

## Decision

Option 1. `banded_rate` reads `ok` when the 99% interval lies inside the band, whether or not it holds the chance.
An interval that crosses a band edge keeps its earlier verdict: `measured` when it holds the chance, `alert` when it
does not; an interval outside the band alerts. The change can only turn an `alert` into `ok`.

## Consequences

- Templar has no `band` proc entry and no `cooldown_reset_rate` entry (classes/templar*.json and
  fixtures/classes/templar.json): no Templar label can change; Templar `generate --class 19` and `--stack` are
  byte-identical.
- Seeded tests: test_compare.py `BandedRateTests` (inside the band but excluding the chance passes; across an edge
  and excluding it alerts; holding it across an edge stays measured; outside the band alerts).
