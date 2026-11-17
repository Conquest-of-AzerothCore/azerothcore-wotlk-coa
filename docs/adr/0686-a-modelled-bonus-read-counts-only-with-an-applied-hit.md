# 0686. A modelled bonus read counts only with an applied hit of the same claim

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0679, ADR 0683

## Context

ADR 0683 made a modelled `spell_bonus_data` read prove the CalcValue roll only: a claim whose stated value includes an
AP or SP term must also list a hit-based label, with a spell power arm where the claim states a spell power term
(G-27 extension, mentor D-57). It left the condition to the ledger and named the shared check that would enforce it.
Mentor D-61 (approved under O-12) asks for that check in `coverage.claim_evidence`, with no change to a finished
class's count.

## Options

- Keep the condition in the ledger: a ledger row that lists only the modelled read still counts.
- Refuse every claim with a modelled read: also refuses the claims whose hit entry measures the full amount.
- Refuse a claim with a modelled read unless an applied hit of the same claim passes, and, for a row with a spell
  power coefficient, unless that hit ran at a non-zero spell power.

## Decision

- `coverage.bonus_terms_unproven(matched)`: when a matched verdict of the claim carries a `bonus_data` dict (the
  modelled row of `compare.judge_roll`; the `not_measured` string case is already unproven), the claim needs another
  matched verdict that is a conformant applied hit (`applied_hit`): a check of `compare.HIT_CHECKS` (`hit_mean`, which
  `script_hit` entries also write, `melee_mean`, `periodic_total`), `behaviour_hit_ratio`, or a
  `behaviour_metric_delta` whose metric is `spell_damage_total`, `spell_heal_total` or `melee_damage_total`
  (`BONUS_HIT_METRICS`). A `closed` verdict is not a hit.
- When any such row has a non-zero `direct_bonus` (the spell power coefficient; periodic rows are not modelled, ADR
  0679), the hit must also carry `detail['spell_power']` above 0 (`HIT_SPELL_POWER`).
- `claim_evidence` returns `unproven` for a refused claim, so its clause does not count.

## Consequences

- No hit judge records `detail['spell_power']` yet: a claim whose row has a spell power coefficient stays refused
  until a hit entry with a spell power arm records it (a follow-up of the tool). Witch Hunter: Torchlight 503662
  (`direct_bonus` 0.45) is refused on `503662 hit_mean` alone, as ADR 0683 states; Flourish 805365 (row 807762,
  `direct_bonus` 0) counts with its passing `flourish_damage` pulse. On the final05 run-2 verdicts both claims were
  already unproven, so the Witch Hunter audit there is unchanged (401 claims, 59 behaviour, 182 data, 160 unproven,
  before and after).
- Templar (19) and Necromancer (23): none of their 1,870 archived verdict files (class-conformance,
  class-conformance-2, class-conformance-3 and class-conformance-necromancer plans) holds a `bonus_data` dict, and
  none of their `effect_value` owners has a non-zero row (ADR 0679), so the check never applies and their counts are
  unchanged. Generation is untouched (the change is in coverage only).
- Tests in `test_coverage.py` (`BonusTermProofTest`): a modelled read alone is refused while a plain read stays data;
  an AP-only row counts with a passing `hit_mean` or a damage-total metric delta of the same claim; a hit of another
  claim, or a non-hit metric delta, does not lift the refusal; a spell power row counts only with a hit at a non-zero
  recorded spell power. Mutant: with `bonus_terms_unproven` patched out, the modelled read alone counts as data and
  the spell power row counts on a hit without a recorded spell power, which the unpatched rule refuses.
