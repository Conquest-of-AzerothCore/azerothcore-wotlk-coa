# 0616. A contrast-gated read is behaviour evidence only with its contrast

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0553, ADR 0584, ADR 0615

## Context

Three Necromancer claims were ok in both runs of the cycle 8 pair 20261113-192548 / -194835 and read as data:
9.1 "and your summons by $s2%" (summon crit reads, state metrics whose promise words sit in the row's other part),
86.2 "(8 sec vs players)." (`aura_duration_ms`, a readback, on an enemy player) and 172.1 "at random" (a pick share
whose verdict stamped `cooldown_ms`, a readback). Each read is a talent against no talent (or a control cycle)
measurement of the thing the claim states; the bare read is not. Overriding the base rows of `aura_duration_ms` and
`cooldown_ms` is refused (`KIND_ROW_OVERRIDES` stays empty) and both metrics are read by Templar entries.

## Options

1. Move the metrics to `event`: changes every class reading them and the contrast chosen at generation.
2. A gate table, `coverage.CONTRAST_PROOF` (kind modules add rows): a metric listed there is behaviour evidence only
   when the verdict's `detail.contrast` equals the row's contrast; otherwise the existing class applies unchanged.
   The two overloaded metrics are replaced for the entries concerned by their own names.

## Decision

Option 2. `CONTRAST_PROOF` holds `owned_creature_spell_crit_chance` and `owned_creature_school_spell_crit_chance`
(`learned`, the summon's crit with and without the talent) and `enemy_player_aura_duration_ms` (`learned`). A
`metric_delta` entry may carry `evidence_metric`, which its verdict stamps in place of `metric`; the Bonefreeze
`player_duration` entry names `enemy_player_aura_duration_ms` (registered `readback`). The `cooldown_pick_share` kind
stamps `cooldown_pick_share` (registered `readback`, gated `learned`) and stamps `contrast: learned` only when its
control cycles ran and picked nothing.

## Consequences

- Without its contrast (a condition or own-cast contrast, a missing control cycle, an alert) the same read stays data
  or unproven; the base rows and `KIND_ROW_OVERRIDES` are unchanged.
- Templar entries carry no `evidence_metric`, so `generate --class 19` is byte-identical.
- Seeded tests: `test_coverage.ContrastProofTest`, `kinds/test_cooldown_pick_share.py`.
