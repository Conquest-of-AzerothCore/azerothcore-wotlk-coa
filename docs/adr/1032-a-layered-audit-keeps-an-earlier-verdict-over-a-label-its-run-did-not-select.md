# 1032. A layered audit keeps an earlier verdict over a label its run did not select

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
replaces.

## Options

1. Keep the merge and drop the narrow sets from counting audits: the controller has to know which labels each set
   ran, and a layered count stays wrong when one is forgotten.
2. Skip, over an earlier layer, a verdict whose `runs` list is empty. A verdict with runs (whatever its status) and a
   verdict without a provenance field (`runs` absent, written before provenance) replace as before.
3. Skip by status (`unmeasured`, `unmodelled`): an `unmeasured` verdict from a trial that ran but saw no event is a
   real outcome and would be hidden.

## Decision

Option 2, in `audit.py`:

- `selected(verdict)` is true when `runs` is absent or holds at least one run id.
- `merged_verdicts` skips an unselected verdict whose label an earlier layer already holds; a label first seen in a
  layer is taken whatever its provenance, so `results_added` is unchanged.
- The audit document lists the skipped labels in a new key `results_not_selected`; `results_replaced` and
  `results_added` hold only the labels a layer actually set.

## Consequences

- The s1 layered audit (same inputs, b11s1 ledger) gives 301/75/43 instead of 288/74/57: the 14 lost claims come
  back, and against the base set alone (300/75/44 on that ledger) the one change is 680637 claim 179 gaining
  behaviour from its new 570187 explosion labels. `results_replaced` falls from 244 to 18 labels,
  `results_not_selected` holds 226.
- Single-directory audits are unchanged except for the new empty key: the Necromancer final16 runs (393/3/13), the
  Templar ledger-only and c3 restore audits, the Witch Hunter pr-focus pair and the Sun Cleric base 11 set give the
  same figures, rows and statuses. Layered audits change only where an unselected verdict had replaced a different
  status (Witch Hunter leech-focus layering: 804068 claim 351 becomes behaviour; Necromancer final16 layered: no
  status change).
- A ledger or class-file verdict with no run (`closed` or `unmodelled` from a rule) no longer replaces an earlier
  layer's verdict for the same label. A rule change of that kind is counted on a full compare used as the base, as a
  merged pair already is.
- `results_disagree` still compares every verdict of the `--results` directories, unselected ones included.
