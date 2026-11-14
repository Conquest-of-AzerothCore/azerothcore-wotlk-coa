# 0655. A conformance cycle script runs the integrator's fixed steps

- Status: accepted
- Date: 2026-11-14

## Context

Each Necromancer merged pair repeated the same integrator steps by hand: the Templar gate, the digests, `generate`,
the source stage, two gameplay runs with a disk check, `compare` and `audit` per run, a tally, a refactor gate and an
archive. The tally and the gate lived in per-cycle copies (`tally15.py`, `tally16.py`, `refactor_gate.py`) whose
paths, stamps, manifests, rulings and kind lists were constants edited for each cycle; `tally16.py` was `tally15.py`
with three names changed. A wrong constant changes the count of record without any visible error.

## Options

- Keep the per-cycle scripts and a checklist: every cycle edits code that decides the count.
- A shell wrapper around the existing commands: the tally and the refactor gate still need Python and their
  constants.
- One `conformance.py cycle` command reading every input from a cycle file, with the tally as a tested module.

## Decision

`conformance.py cycle --config cycle.json` (`cycle.py`) runs the steps in a fixed order: gate, digests, generate,
source, runs, compare, audit, tally, refactor, archive, checkpoint. Each step can be skipped (`--skip`) and logs under
the output directory; the first failure stops the cycle. Every constant of the per-cycle scripts is a cycle file
field: worktree, head, base, ledger, record status file, stamps, compare outputs and manifest, the pair, the build,
the runners, workers, disk limit and checks, guarded classes, moved kinds and seed-suspect words. Candidates, rulings,
ledger-only re-audit corrections and intended text changes are read by claim key from a decisions file. `tally.py`
keeps the rules of the per-cycle tally: statuses 1-5, the flip rule within the pair and against the record (with
changed scenarios and judges excluded), re-audit corrections counted at once, candidates gaining status 1 only on
behaviour in both runs with every label conformant. It adds loud refusals the per-cycle scripts lacked: a decision key
that names no ledger claim, a ruling of status 1 (status 1 needs a pair with no flip, class-conformance.md 3.2) and a
recorded status 3-5 claim without a ruling stop the tally; a record row no ledger claim reaches is a `LOST` line
counted in the delta; the against-record flip test covers scenarios the pair has no result for. The runs step stops on
a run that does not end `PASSED` (exit 0) or `INCOMPLETE` (exit 3) with a gameplay run, on a missing `report.json`
and, as `prove` does, on scenarios without a result. The checkpoint (`checkpoint.json` and `.md`) records the count,
the delta, the flips, the lost and gained claims, the stamps, the build and a `cost` field ("not recorded" without a
cost file).

Replay proofs, from the archived compare outputs with the run steps skipped: cycle 17 (20261114-071744 / -074148)
gave a status file byte-identical to `final15-status.json` (626 / 627, 389.0 lost on its flip) and a refactor gate
equal to its 84 recorded rows; cycle 18 (20261114-084514 / -090752) gave one byte-identical to
`final16-status.json` (627 / 627, 0 flips), with the Templar gate and both digest checks passing.

## Consequences

- Tests: `test_tally.py` and `test_cycle.py` on frozen fixtures under `conformance/fixtures/cycle/` (rows of the
  cycle 17 and cycle 18 pairs and of their record), in the `conformance` suite.
- An agent is needed only where the script stops: merge conflicts, flip causes, candidate rulings.
- The cycle file and its decisions file are cycle inputs kept with the class plan, not in the repository.
