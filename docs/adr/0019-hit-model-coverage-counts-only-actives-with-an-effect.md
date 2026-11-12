# 0019. Hit-model coverage counts only actives with a damage or healing effect

- Status: accepted
- Date: 2026-11-07

## Context

Phase 2's `coverage.md` reports "actives with a hit model" over `spells - passives`, the full set of 49 Templar
actives. The phase-3 recon of 2026-11-07 read `verdicts.json` and found that 33 of those 49 have a `hit_mean`
verdict whose `explanation` is exactly the `hits.py:154` f-string, prefix "no damage or healing effect" — buffs,
utility casts and proc-only spells that structurally cannot have a hit model. Dividing by 49 reports 13/49 (26.5%)
and reads as if two-thirds of the class is unchecked, when 33 of the 36 unchecked actives can never gain a
`hit_mean` verdict at all; the honest comparison is against the 16 actives that do have a damage or healing effect.

## Considered options

1. Keep the single denominator (all actives). Rejected: the percentage conflates "not yet checked" with
   "cannot be checked", understating progress and giving no signal of how close the checkable set is to done.
2. Replace the denominator with "actives with an effect" and drop the old row. Rejected: this breaks the
   phase-2 trend line in `coverage.md`, which readers compare run to run.
3. Add a second row with the new denominator, keep the old row unchanged. Chosen.

## Decision

- `hits.py` names its "no damage or healing effect" reason as the constant `NO_HIT_EFFECT`, so `coverage.py` can
  match on it without duplicating the f-string.
- `coverage.py`'s `spell_sets()` gains `hittable: frozenset[int]`: actives (`spells - passives`) whose `hit_mean`
  verdict's explanation does not start with `UNMODELLED + NO_HIT_EFFECT`. Every active has exactly one
  `hit_mean`-labelled verdict (judged, measured, or unmodelled), so this is a direct filter over `own`, no new
  traversal.
- `Coverage` gains `actives_with_effect: int` (`len(sets.hittable)`); `coverage_lines()` prints a fourth row,
  "actives with a hit model (of those with an effect)", same numerator (`actives_with_hit`), new denominator.
  The existing "actives with a hit model" row (old denominator, 49) is kept as written, for trend continuity.

## Consequences

- The Templar denominator for the new row moves from 13/49 (26.5%) to 13/16 (81.3%) with no verdict changed —
  the correction is purely in what is reported, not in what is measured.
- A future class's `coverage.md` carries both rows; a reader who wants "how much of the checkable set is checked"
  reads the new row, a reader tracking the phase-2 series reads the old one.
- `NO_HIT_EFFECT` is now the single source of that reason string; a future change to the wording in `hits.py`
  needs no matching edit in `coverage.py`.
