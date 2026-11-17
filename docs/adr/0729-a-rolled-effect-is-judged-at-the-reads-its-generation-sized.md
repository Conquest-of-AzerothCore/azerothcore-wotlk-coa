# 0729. A rolled effect is judged at the reads its generation sized, on request

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

An `effect_value` label of a rolled effect (EffectDieSides above 1) is read `samples` times and judged against the
uniform mean of its roll with a 99% half-width of 1% of the mean (`mean_samples`). The generator sizes `samples` from
the tooltip read with the structure stats (`structure_stats`: every stat, attack power and spell power at the
placeholder 1.0); the judge sized the same requirement again from the tooltip read with the measured stats. A token
with a stat term therefore gets two different counts: Tormentor 501349 `effect_value e2 #0`
(`${$cond($gt($sps, $sph), $m3+0+$sps*.175, ...)}`, roll 61..72) is generated with 178 reads at spell power 1
(mean 66.675) and judged with spell power 0 (mean 66.5), which needs 179, so the label ended `measured`
("needs 179 reads, more than the scenario holds") in both runs of the c13 tool pair. Mentor decision D-192 (defect
fix).

## Options

- The judge asks, for an entry that opts in, for the smaller of its own count and the count the generation sized, recomputed with the same
  placeholder stats (`sizing_stats`) and the same tooltip value.
- Size the generation with the class reference stats: changes the sample count of every rolled token with a stat
  term, and the Templar 19 and Necromancer 23 scenarios with it.
- Read the planned count from `model['samples']`: it is 1 when the read budget cut the sampling, so the judge could
  not tell a sized plan from a cut one.

## Decision

The change is opt-in (mentor D-195): a class-file `effect_overrides` entry sets `"placeholder_sample_count": true`
for its `spell` and `effect`. Only a flagged label takes the smaller count; every other label is judged exactly as
before commit a78bf0d22b. D-195 rule: no shared judging change may reach a finished class unless its verdicts are
shown unmoved.

The first option. The placeholder stat is 1.0 and the measured stats are never negative, so the two counts differ by
the effect of one point of a stat term on the mean; the judged interval itself still uses the measured reads and the
roll's own sigma. A plan the read budget cut to one read still needs the full count and stays `measured`.

## Consequences

- No generation change: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests (`test_compare.py`): a `$sps` roll of 61..72 with spell power 0 measured is judged at 178 reads (ok)
  and stays `measured` at 177 (the seeded short scenario, the alerting mutant of the check); the existing rolled-read
  tests keep the measured count where it is the smaller one.
- A seeded test judges the same unflagged input at 179 reads (`measured`) and the flagged input at 178 (`ok`).
- Witch Hunter: the 501349 effect 2 `effect_overrides` entry carries the flag, so 501349 `effect_value e2 #0` is judged instead of `measured`.
