# 0122. Prove fails when any scenario of the manifest has no result

- Status: accepted
- Date: 2026-11-11

## Context

ADR 0121 ported the prove runner with its known defect I3 (prototype `score.md` §7): a run failed only when no
scenario had a result. In the prototype's X1 trial a worldserver crash in `Player::ApplyModToSpell` removed 35 of 36
scenario results per mutant run, controls included, and `prove` still exited 0: the missing scenarios simply gave no
verdicts, so they produced neither a flip nor an alert. The owner's fix order of 2026-11-11 puts I3 first: a runner
that reports success on missing results invalidates every figure it produces.

## Considered options

1. Keep exit 0 and list the missing scenarios in the summary. Rejected: callers and agents read the exit status.
2. Count a missing scenario as a flip (exit 1). Rejected: a flip says two judged verdicts differ; a missing result is
   a failed run, and it can be missing in every run alike.
3. Fail the proof at the first run (pilot included) in which any scenario of the manifest has no result, with its own
   exit status, and name the scenarios. Chosen.

## Decision

- `compare_run` returns the scenario keys without a result (`Comparison.missing`), not their count.
- `execute_run` records them in the run record (`missing_results`, `scenarios_without_result` stays the count) and
  raises `ProveFailure` with `MISSING_EXIT` (3) when the list is not empty. The failure message gives the count, the
  total and the keys.
- `summary.json` gains `missing_results` (run directory and scenario keys) and `failed_run` (that run's record).
  No fragment is written; no later run starts.
- Exit status: 0 no flip, 1 a flip, 2 scenario drift, 3 a scenario without result, 4 a failed run. Exit 0 now means
  a result for every scenario of the manifest in every run.

## Consequences

- A crash that removes some results can no longer pass as a clean proof; the rerun is a new prove into a new
  directory once the cause is understood.
- A run with no result at all is exit 3 as well, no longer exit 4.
