# 0121. A deterministic prove runner for class-file entries

- Status: accepted
- Date: 2026-11-11

## Context

Rounds 1-10 of the class conformance work ran gameplay through agents: each agent generated scenarios, called
`coa-verify`, compared the stamp, repeated a run when it doubted a verdict, and wrote ledger rows by hand. The number
of runs, the stability check and the rows therefore depended on the agent. The clause-spec prototype built a runner
(commits b0c572bb3e, 879864050a, a6322d5032) that its option C control arm also used for current-method entries
(`--behaviour`, `--proc`, `--trigger`; 9559827787, 052fed01ff). The owner kept it with its flip rule and pilot sizing
on 2026-11-11 (ADR 0116).

The prototype's flip rule came from its S2 smoke: an entry judged `ok` in run 1 and `insufficient_trials` in run 2
(2.53% against a 2.5% power limit) was reported as a flip. `insufficient_trials` says the run was too small to judge,
not that the server changed.

## Considered options

1. Keep agent-driven passes and ask for two runs in the brief. Rejected: the runs, the rows and the flip check stay
   unverifiable.
2. Call `verify_all.py` stages directly. Rejected: the project routes every run through `coa-verify`, which mounts
   the worktree, the main checkout and the server data.
3. One subcommand, `conformance.py prove`, that generates the chosen class-file entries, runs them through
   `coa-verify`, compares, diffs and writes a ledger fragment and a summary, every external step injectable for
   tests. Chosen.

## Decision

- `prove.py` generates through an injected function, runs `coa-verify --worktree W --ram --stages [build,]gameplay
  --scenario <files>` in the foreground (no `--jobs`; `build` on run 1 only), compares each run, and fails on a
  timeout (the process group is stopped), a missing `VERIFY ALL` line, a failed build stage, scenario drift (own exit
  status), results of several builds, a run with no result, or runs judged on different builds.
- At least two runs. A flip is two judged verdicts whose status classes differ, or a label present in one run only;
  `ok` against `tolerated` is not a flip; `insufficient_trials` is not judged, never flips, and is listed in
  `not_judged` with the largest `trials_needed`.
- A `Pilot` (generate, size, sized) can run once before the judged runs, never judged, on the same build. The
  prototype's only provider sized MAGNITUDE clause entries; the command passes none.
- `prove_ledger.py`: with `--clauses`, the fragment lists the ledger claims whose labels all run in the batch and are
  conformant in every run, with the evidence of the two proof statuses (ADR 0120, behaviour only when every run says
  so); the summary carries the ledger coverage of each run.
- `--out` must lie under the worktree or its main checkout.

## Consequences

- A proof costs two gameplay runs, and its cost is readable from `summary.json` (`gameplay_seconds` per run).
- The prototype's review (I3) found the runner exits 0 when most scenarios have no result (35 of 36 after a
  worldserver crash): a run fails only when no scenario has one. That is fixed in its own step, not here.
- Sizing from a pilot exists only as the hook until a kind of the current method takes a trial count from it; the
  power checks of the I8 step are the first candidates.
