# 0240. One fixed-count label suffix

- Status: accepted
- Date: 2026-11-12
- Refines: ADR 0221 (its `label_suffix` naming), with ADR 0235

## Context

Two branches gave `fixed_count` a `label_suffix` independently. ADR 0221 (Norgannon's Wrath 524739 `cap` and
`cap_control`, R2) appended it to the count: `<spell> behaviour_fixed_count <suffix>`, and left the dummy reads as
`<spell> <dummy> <metric> <moment>`. ADR 0235 (Holy Edge and Holy Cleave, R3) put it after the spell id in the count
and in every dummy read: `<spell> <suffix> behaviour_fixed_count` and `<spell> <suffix> <dummy> <metric> <moment>`.
One field cannot carry both forms.

## Options

1. ADR 0235's form for every entry: two entries (524739 `cap`, `cap_control`) change labels.
2. ADR 0221's form for every entry: seven entries (Holy Edge's six, Oath: Holy Cleave under Combat Training) change
   labels, and their dummy reads lose the suffix that keeps two entries of one spell apart.
3. Two fields, one per form.

## Decision

Option 1. `fixed_count` labels follow ADR 0235. The two 524739 rows of the clause ledger name
`524739 cap behaviour_fixed_count` and `524739 cap_control behaviour_fixed_count`.

## Consequences

- The 524739 `cap` and `cap_control` scenarios no longer regenerate byte-identical: their labels change, nothing else.
  They are rerun twice on the merged build. Verdicts stored under the old labels stay valid evidence for their runs but
  no longer match the ledger.
- Every other `fixed_count` entry regenerates byte-identical.
