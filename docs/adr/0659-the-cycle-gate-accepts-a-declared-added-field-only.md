# 0659. The cycle gate accepts a declared added field of a guard class, and nothing else

- Status: accepted
- Date: 2026-11-14

## Context

The `gate` step of `conformance.py cycle` (ADR 0655) regenerates every generation of each guarded class at the
worktree and at the base and requires `diff -r` to find no difference. ADR 0658 adds `min_level_armor` to the
generated creatures, so the Necromancer shared-pass cycle (2026-11-14) found 1942 Templar scenario files and the
manifest different, all by that field alone. The only way on was `--skip gate`, which also dropped the gate's
`snapshots.py check` of the guard class.

## Options

1. Keep the plain `diff -r` and skip the gate for intended changes.
2. Check the head generation against the committed snapshot digests only.
3. Let the cycle file declare the intended change, and accept a difference only when it is exactly that change.

## Decision

Option 3. A cycle file field `gate_accepted` names, per guard class, the keys the branch adds to the generated
files (`added_fields`) and why. When `diff -r` finds a difference for that class, the gate compares the files: each
differing scenario file must equal the base file once the named keys are removed from the head file at any depth;
the manifest may differ only by those keys and by the sha256 of the files that changed that way. A key present in the
base file is therefore never accepted as changed. Any other difference, a file in one tree only, or a declared change
that no generated file shows stops the gate. `snapshots.py check` still runs for the class.

Option 1 loses the guard and the snapshot check on every intended change. Option 2 needs the branch to refresh the
committed digests first and cannot say what changed.

## Consequences

- An intended fixture field is accepted without `--skip gate`, and the gate log states how many files changed and why.
- Only additions are expressible. A changed value or a removed key needs a new decision.
