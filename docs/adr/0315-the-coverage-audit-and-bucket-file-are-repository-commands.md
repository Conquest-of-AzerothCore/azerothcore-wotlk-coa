# 0315. The coverage audit and the bucket file are repository commands

- Status: accepted
- Date: 2026-11-12

## Context

The Templar's batches drew their samples from a bucket file built by two uncommitted scripts
(`.agents/plans/class-conformance-3/lean/batch1-prep/coverage_audit.py` and `buckets.py`). They hard-coded their
paths, the Templar family 25, the class code glob `AscensionTemplar*`, a round 10 base verdict set, a hooked-label
list, a prototype standing-alert file and two settled alerts. A second class could not run them, and the guide
(`docs/coa/class-conformance.md` 9.6 and 13) listed the bucket builder and the aura 354 check as future work.

The audit script also kept a label of the latest runs only when both runs agreed by status class, and computed a
second coverage under the coverage rule that ADR 0131 replaced ("before ruling").

## Considered options

1. Commit the scripts as they are. Rejected: every input is Templar-specific.
2. One command that audits and buckets in one pass. Rejected: `packets` and reviewers read the audit on its own, and
   the audit is the only step that needs compare outputs.
3. Two commands, `audit` and `buckets`, with every input an argument. Chosen.

## Decision

- `conformance.py audit` merges `--base-results` and then each `--results` in order; a later directory replaces the
  labels of the earlier ones, and labels whose status class differs between `--results` directories are listed in
  `results_disagree` for the controller to judge. It does not drop them as the Templar script did: the merge rule is
  the same for any number of runs, and the list keeps the disagreement visible. It runs with no verdicts.
- The "before ruling" coverage is not computed: ADR 0131 is in force and the old rule is not a repository rule.
- `conformance.py buckets` reads the class code from the class map's `own_files`, or the glob
  `src/server/coa/**/Ascension<class name>*`, and the family from the class map or the most common `SpellFamilyName`
  of the class spells. Settled alerts and standing alerts from outside the audit set are optional input files
  (`{spell, clause[, why]}` lists), not constants.
- `conformance.py aura354` lists a class's aura-354 spells from a class map and flags those of risk `stock` or
  `data_row`.

## Consequences

- A new class builds its bucket file without editing code: `audit` on its first ledger gives every claim unproven,
  and `buckets` buckets every claim `U`.
- On the Templar's inputs (batch-1 audit, a manifest regenerated at 6cbd4ed4fe, the class code of that commit, the
  settled and standing alerts as files), `buckets` reproduces `bucket`, `evidence`, `script_touch` and `token_kind`
  on all 433 rows. The batch-1 audit cannot be rerun: its base and latest verdict sets no longer exist.
- `buckets` without a class map reads more files than the map's `own_files` (headers and files with few hits), so the
  two sources can give different `script_touch_hits`; the bucket file records which one it used.
