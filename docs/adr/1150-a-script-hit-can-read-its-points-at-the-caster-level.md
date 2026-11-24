# 1150. A script hit can read its points at the caster level

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0014 (helper points at the client level), ADR 0147 (per-level truncation), ADR 0996 (value_rolls)

## Context

Spirit Volley 503712 states `${$m1+0+$RAP*.285}` for its helper 504582 (BasePoints 320, DieSides 75, 1.85 per level
from BaseLevel 50, MaxLevel 0). The tooltip reader reads a helper `$m1` at the client level (ADR 0014), level 0 for a
spell without a skill line, so it expects 334 to 408. `SpellEffectInfo::CalcValue` adds the per-level term at the
caster level (10 levels at 60: 18), and the value scenario read 409 to 426. Mentor ruling M-46 holds that DBC term the
server's right value (pitfall 13). A script hit of the Volley had no way to model it: its model reads the same tooltip.

## Decision

`script_hit` takes `level_points: true`. Every roll of the hit effect's die is then forced to base + roll + the
CalcValue per-level term at the caster level (level clamped to BaseLevel and MaxLevel, minus the larger of BaseLevel
and SpellLevel, float32) through `UnscaledForcedPoints`, so the tooltip formula is read once per roll with the
server's points and a `$ppl` token of that effect adds nothing more; the existing engine model then truncates the
term (ADR 0147). A die of 1 is read as one roll. The option refuses weapon, normalized and value-spell hits
(`Unmodelled`). The expectation record carries `level_points`, the rule names the CalcValue level.
`hits.calc_value_term` holds the term that `per_level_fraction` already computed.

## Consequences

Absent, nothing changes: generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical.
Class 13 gains 503712 `volley_hit` (model 389.0 against the level-0 371.0). A server without the per-level term reads
about -4.6%, inside the hit judge's 5% tolerated band, so the option fixes the expected value, not the judge's
resolution.
