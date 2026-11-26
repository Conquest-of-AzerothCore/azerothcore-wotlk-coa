# 1304. Primary attributes promise on stat_exact requires all five stats

- Status: proposed (provisional number, renumbered at merge)
- Date: 2026-11-25
- Builds on: ADR 0190 (state promises), ADR 1283 (`CLAIM_STATE_PROMISES`)

## Context

Cultist Empire Commander (704887 rank 1 +4%, 707781 rank 2 +8%, 712470 rank 3 +12%) states "Increases all primary
attributes by $s1%." (`Spell.dbc` Effect[0] aura 137 `SPELL_AURA_MOD_TOTAL_STAT_PERCENTAGE`, `MiscValue = -1`). The
Cultist class file already measures all five unrounded live stats (`stat_exact`, `stat` 0..4: Strength, Agility,
Stamina, Intellect, Spirit) in a learned contrast (`behaviours[63..77]`), and each ledger row (rows 295, 337, 343)
links all five labels.

`coverage.STATE_PROMISES['stat_exact']` matches only individual stat names (`strength|agility|stamina|intellect|spirit`)
so the audit classes all three rows as `data` even when all five live stat ratios pass. Adding `primary attributes`
unconditionally to `STATE_PROMISES['stat_exact']` would let a claim linking only one of the five stats count as
behaviour without measuring the other four. Widening `CLAIM_STATE_PROMISES` (ADR 1283) also applies only to declared
`claims[]` rows and was cautioned against in review `cu-rt10` where a direct, stricter gate is cleaner.

## Options

- Split each row into five declared claims naming each attribute. Refused: breaks Cultist's ledger guard and inflates a
  single percentage clause into five counted parts.
- Add `primary attributes` directly to `STATE_PROMISES['stat_exact']`. Refused: a single passing `stat_exact` read
  would mark an "all primary attributes" claim behaviour proven while leaving four attributes unmeasured.
- Stamp `model['stat']` opt-in when `stat_exact` quotes `primary attributes`, propagate it to `verdict.detail['stat']`,
  and accept the `primary attributes` promise in `coverage.py` only when the claim's own conformant learned/own-cast
  `stat_exact` verdicts cover all five stats `{0, 1, 2, 3, 4}`. Chosen.

## Decision

- `behaviours.metric_delta_scenario` adds `model['stat'] = int(spec.fields['stat'])` only when
  `spec.metric == 'stat_exact'`, `'stat' in spec.fields`, and `entry.quote` matches `\bprimary attributes\b`
  (case-insensitive). Existing single-stat `stat_exact` entries in finished classes do not match and regenerate
  byte-identical.
- `compare.observed` copies `model.get('stat')` into `verdict.detail['stat']` when present.
- `coverage.primary_attributes_measured` accepts a `behaviour_metric_delta` `stat_exact` verdict in a `learned` or
  `own_cast` contrast for a clause matching `\bprimary attributes\b` only when the claim's own conformant non-closed,
  non-`data_only` `stat_exact` verdicts cover every stat id in `{0, 1, 2, 3, 4}`. A sibling claim's verdicts in the same
  row cannot supply a missing stat.

## Consequences

- Cultist Empire Commander rows 295 (704887), 337 (707781) and 343 (712470) audit as `behaviour` once all five
  `stat_exact` labels pass in a counted pair, without editing the ledger rows or splitting them.
- Any partial measurement (fewer than all five distinct stat ids, duplicate stat id, unstamped verdict, non-learned
  contrast, or `stat` instead of `stat_exact`) stays `data`; any alerting or unmeasured stat makes the row `unproven`.
- Finished classes regenerate byte-identical: no finished class has a `stat_exact` entry quoting `primary attributes`
  (Templar Pious 706431 uses `passive_delta` `stat` with `data_only`, untouched).
