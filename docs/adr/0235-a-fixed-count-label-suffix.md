# 0235. A fixed-count label suffix

- Status: accepted
- Date: 2026-11-12

## Context

Holy Edge 706312 and 707853, claims 229 and 269: "Damage dealt by Scourgebane and Scarlet Hammer now strikes $s1
additional nearby enemy." One talent names two spells, so it needs two `fixed_count` entries, plus their controls.
Their labels were built from the talent's id alone (`<spell> behaviour_fixed_count`, `<spell> <dummy> <metric>
<moment>`), so the entries' readings merged in one verdict.

## Decision

`fixed_count` reads `label_suffix`: the expectation becomes `<spell> <suffix> behaviour_fixed_count` and every dummy
read `<spell> <suffix> <dummy> <metric> <moment>`. Entries without it regenerate byte-identical.

## Consequences

- On build 2a99d5b855eb, both runs: with rank 1 learned, Scourgebane 801832 and Scarlet Hammer 807035 reach their target
  and 1 of 2 candidates, with rank 2 2 of 3, the dummy beyond 10 yd never; without the talent (the controls) neither
  reaches a second dummy.
- Seeded tests: two entries of one spell read disjoint labels; the talent is learned and the count carries the suffix.
