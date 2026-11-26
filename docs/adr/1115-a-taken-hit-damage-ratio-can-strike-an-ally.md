# 1115. A taken-hit damage ratio can strike an ally

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0153 (taken_hit), ADR 0763 (struck ally for the absorb judge)

## Context

Big Bad Voodoo 802719 "While allies are within $a2 yds, their damage taken is reduced by $s2%" and One Armed Waltz
705909 "and reduces damage taken by an additional $s3%" (clauses 471, 472, 209; tool note T-c9-B16-11, proposal 1036):
the reduction reaches allies in the spell's area, while the caster is school-immune inside the spirit's field and cannot
be the struck unit.

## Decision

- `taken_hit` accepts `struck: "ally"` with `judge: "damage_ratio"` as it already did with the absorb judge (creature
  striker, no debt, returned hit, caster health or `health_loss`). The strike is cast at the grouped ally, the ally is held
  at full health before every trial, and the non-critical strike logs on the ally are judged as a hit ratio.
- Witch Doctor entries `802719 behaviour_hit_ratio ally_taken` (0.80) and `705909 behaviour_hit_ratio waltz_taken`
  (0.75), Void Zone 92559 strikes after one real Big Bad Voodoo in the treatment arm.

## Consequences

- A validation is widened; no default changes. Classes 19 (with and without `--stack`) and 23 generate byte-identical.
- Seeded test in `test_landed_rate_and_ally_strikes.py`.
