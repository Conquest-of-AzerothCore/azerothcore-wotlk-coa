# 1280. A threat claim without a figure is judged above a control hit

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-24

## Context

Fel Torpedo 500610: "Generates a large amount of threat." The tooltip gives no figure. `threat_slope` judges a
stated slope; the only number available is our own `spell_threat` row for the hit 500761 (pctMod 3.25,
rev_20261026_20_coa_tank_ability_threat.sql), which is server data and not an expectation (mentor D-106,
2026-11-24). The mentor ruled the claim a direction: Fel Torpedo's threat per damage strictly above a control hit's,
with non-overlapping samples. No kind compared two hits' threat per damage sample by sample.

## Considered options

- `threat_slope` with `expected_slope` 3.25: refused by D-106 (our own SQL value).
- A `threat_slope` option with a minimum slope: a new judge input on a shared kind, and a bound still has no source.
- A new kind module comparing samples of the hit and a control hit (chosen).

## Decision

`kinds/threat_above_control.py`: `samples` (3 to 5) casts of `hit_spell` and of `control_spell`, alternated, each at
its own fresh dummy, 10 yd apart on one line with the caster stepping 10 yd before each cast. A sample is threat
gained over health lost. `ok` when the lowest hit sample lies strictly above the highest control sample, `alert`
otherwise; `unmeasured` on a failed cast or no health lost. Metric `threat` (an existing state row of
`coverage.METRIC_EVIDENCE`) with contrast `own_cast`, so the verdict is behaviour only for a clause that says
"threat". Fresh dummies are needed because a second direct 500761 cast on a dummy is dropped by the per-cast hit list
(owner ruling O-25, Felsworn ADR 0013), and the harness has no threat reset.

## Consequences

- No new row in the closed evidence tables; no change to existing judges. An entry without this kind generates the
  same scenarios: classes 15, 19, 19 --stack, 23 and 27 regenerate byte-identical.
- Felsworn: `500610 behaviour_metric_delta threat_above_control` (hit 500761 against Carve's strike 803715). The 3.25
  multiplier stays recorded as observed and unasserted in the claim note.
- Tests in `kinds/test_threat_above_control.py`: the placement and alternation, a passing direction, seeded mutants
  (equal threat per damage, one overlapping sample) that alert, the unmeasured cases and the refusals.
