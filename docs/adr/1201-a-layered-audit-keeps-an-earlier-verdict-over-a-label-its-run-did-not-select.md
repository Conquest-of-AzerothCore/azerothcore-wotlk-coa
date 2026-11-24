# 1201. A layered audit keeps an earlier verdict over a label its run did not select

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-22
- Amends: [ADR 0315](0315-the-coverage-audit-and-bucket-file-are-repository-commands.md) (merge order of
  `conformance.py audit`)

## Context

ADR 0315 has `conformance.py audit` merge `--base-results` and then each `--results` directory in order, a later
directory replacing every label of the earlier ones (`audit.merged_verdicts`, set in 86d9ec0f27). A narrow compare
writes a verdict for every label of its manifest, also for the labels whose scenarios it did not run. Such a verdict
carries an empty provenance list (`Verdict.runs == []`, written by `compare.with_provenance` from the runs of its
scenarios). In the s1 narrow set `value-cmp1`, 33 pooled hit ratios read "0 of N pooled parts ran" with status
`unmeasured` and no run, over `ok` in the base, and 9 `unmodelled` verdicts with no run sat over `closed` ones.

The Sun Cleric s1 re-review audit layered three narrow sets over the pair 11 base: 244 labels were replaced, 226 of
them by verdicts with no run, and 13 behaviour claims and 1 data claim fell from proven to unproven although no trial
had judged them (`recount-diff-s1.md`, figures 288/74/57).

Mentor D-179 ruled that a label a run did not select or measure never replaces a base result; only a measured verdict
replaces. Mentor D-180 added that a verdict judged by rule alone (`closed`, `unmodelled`: a ledger or class-file state,
which has no run by nature) must still replace in a later layer, and that only a label its run did not select is kept
out. An empty `runs` list cannot tell the two apart: a full compare already holds 193 rule-only verdicts with no run.

The review of the first fix also found that a link-derived status is frozen per layer: `compare.resolve_linked_statuses`
closes an `unmodelled` linking verdict when every referenced label is conformant in that compare, so a base `closed`
kept over a later layer that turns a referenced label into an alert would count as data proof.

## Options

1. Keep the merge and drop the narrow sets from counting audits: the controller has to know which labels each set
   ran, and a layered count stays wrong when one is forgotten.
2. Skip, over an earlier layer, a verdict whose `runs` list is empty (the first fix, commit 10848d8480). A rule-only
   verdict can then never update a label.
3. Skip by status (`unmeasured`, `unmodelled`): an `unmeasured` verdict from a trial that ran but saw no event is a
   real outcome and would be hidden.
4. `compare` writes an explicit `selected` marker per verdict, and `audit` skips only `selected: false`; link statuses
   are resolved again after the merge.

## Decision

Option 4.

- `compare.with_provenance` writes `selected = bool(runs) or rule_only`, where a label is rule-only when every manifest
  expectation of it is judged from its rule before any run is read (`closed`, `unmodelled`, `unmeasurable`,
  `generic`, `unreadable`, `ambiguous_tooltip` rule prefixes or the `unmodelled` check, pooled checks excluded:
  `compare.rule_only_labels`). `runs` stays provenance only.
- `audit.merged_layers` skips a `selected: false` verdict whose label an earlier layer holds; a label first seen in a
  layer is taken whatever its marker. A verdict written before the marker (`selected` absent) falls back to the first
  fix: it counts as selected when `runs` is absent or not empty. That fallback never lets an unselected verdict hide a
  measured one; its cost is that an older rule-only verdict with no run still cannot update a label, which a rerun of
  `compare` on the same results removes.
- `compare.resolve_linked_statuses` records each linking verdict's own status in `detail.linked_from` and resolves
  from it, and the referenced labels' own statuses, so resolving twice gives the same result. `audit.relinked`
  resolves again, on the merged statuses, every linking verdict with a referenced label from another layer. A
  link-closed verdict written before `linked_from` (status `closed`, rule not a `closed:` rule) is resolved from
  `unmodelled`, the status `compare` gives such an entry before its links resolve; an older value-link verdict an
  alert closed to `alert` stays `alert`. Links within one layer keep the status `compare` gave them.
- `compare.resolve_base_roll_links` records a `base_roll_only` verdict's own read status in
  `detail.base_roll_only.read_status` and accepts or refuses from it, so resolving twice gives the same result.
  `audit.relinked` resolves it again, after the links above, when its `power_term_label` or `contrast_label` came from
  another layer: a base-roll `ok` of an earlier layer turns `alert` over a later alert on its power term, and a later
  refusal for a label absent from its own comparison is accepted again when the merged labels pass. A refused verdict
  written before `read_status` resolves from `alert`, so it stays refused.
- `results_disagree` compares only selected verdicts. `results_not_selected` lists the skipped labels; a label one
  directory added can also be listed there for a later directory.

## Consequences

- The s1 layered audit (same inputs, b11s1 ledger, sets written before the marker) gives 301/75/43 for run 1 and run 2,
  as with the first fix: the 14 claims lost at 288/74/57 stay restored. Against the base set alone (300/75/44) the one
  change is 680637 claim 179 gaining behaviour from its new 570187 explosion labels.
- On the s1 sets the rule-only update is not visible: they carry no marker, so 804628 e0 keeps the base11 explanation
  until `compare` is rerun on those results (the b11s1 manifest and results are no longer on disk).
- Single-directory audits (Necromancer final16 runs, Templar ledger-only and c3 restore, Witch Hunter pr-focus, Sun
  Cleric base 11) and the Necromancer layered audit are identical to the first fix. The Witch Hunter leech-focus
  layering keeps its figures and statuses; its `results_disagree` drops from 6 rows to none, all of them unselected
  verdicts. Generated scenarios of classes 15, 19 (with and without `--stack`) and 23 are byte-identical.
- No recorded set holds a base-roll verdict, so the base-roll relink changes no audit figure.
