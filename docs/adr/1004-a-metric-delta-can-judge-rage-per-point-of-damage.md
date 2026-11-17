# 1004. A metric delta can judge Rage per point of damage

- Status: accepted
- Date: 2026-11-17
- Builds on: ADR 0582, ADR 0870

## Context

Heartseeking Bolt 807284 (owner ruling O-15 text) "Generates Rage based on the damage dealt." The server gives
`Unit::RewardRage(dealt, 0, true)` per hit (`AscensionWitchHunterAbilities.cpp:453-454`), which is dealt / rage
conversion x 3.75 x 10 raw Rage, truncated once per hit (`Unit.cpp:17677-17708`). The existing `rage` entry
(ADR 0870) proves only that Rage is generated; the proportionality had no read, so the part stayed unproven. Design from
the nf-a stop (Witch Hunter not-final pass), approved by mentor D-465 (category A, judging of existing entries unchanged).

## Decision

A `metric_delta` option module `rage_per_damage` (opt-in): `{"spell", "target", "min_damage_ratio"}`. The entry casts the
spell once per phase with Rage reset to 0 and regeneration off, and a damage contrast in `after_auras`. Before each Rage
reading the option reads the spell's cumulative damage total, hit count and critical hit count at the target, and the
caster's maximum Rage before the after reading. Its verdict replaces the metric delta's:

- the judge: r = (Rage_after / damage_after) / (Rage_before / damage_before); `ok` when |r - 1| <= `tolerance` (the
  G-19 band of 1: 0.05), else `alert`; a before phase with damage and no Rage alerts;
- `unmeasured` when a phase lands other than one hit or a critical hit, deals no damage, the damage contrast is below
  `min_damage_ratio`, or the after Rage reaches the read cap (1000 raw).

Expected value: no amount is stated, so the judged value is the equality of the two Rage rates, never a Rage figure.
Provisional number, renumbered at merge (14.4).

## Consequences

- Entries without the option generate byte-identical scenarios.
- Seeded tests in `metric_delta_options/test_rage_per_damage.py`: the read order, an entry without the option, an `ok`
  reading with truncated Rage, alerting mutants (Rage independent of the damage, a fixed Rage per hit added, no Rage),
  `unmeasured` phases (two hits, no hit, a critical hit, a small contrast, the cap, a missing read, no damage) and refused
  inputs.
<!-- coderabbit-ai-generated:v1 -->

<!-- coderabbit-ai-generated-section:v1:b08456b2a73fa93932935d5be64fbb2b3bfb90f7343e0063d3e807f2969c6231 -->

- At one hit per phase the truncation moves r by at most 1/170 + 1/340 (about 0.9%) at the Witch Hunter's reference
  stats, inside the band: the read is deterministic (false alert 0). A Rage independent of the damage reads 1 / contrast
  (<= 0.667 at the stated minimum contrast) and always alerts; a fixed Rage per hit on top of a proportional part passes
  only while the fixed part is at most 10% of the before phase's Rage at contrast 2, or 15% at contrast 1.5.
  These detection limits depend on contrast at tolerance 0.05.

<!-- /coderabbit-ai-generated:v1 -->
