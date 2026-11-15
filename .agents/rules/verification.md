# Verification

- Freeze the fetched `origin/main` revision when starting PR qualification and record the tested base and
  candidate. Keep the checkout stable while checks run. Review later main changes for relevance before
  integrating them: rebuild or repeat verification only when they affect the changed behavior, its callers,
  build interfaces or effective data, or when an actual failure requires it. Unrelated main updates do not
  restart qualification or delay publication. Finish in-flight checks before integrating relevant updates,
  reuse existing build artifacts, and reverify the affected scope. After required checks pass, publish against
  the recorded base instead of repeatedly chasing the newest main revision. If the user requests publication
  while checks remain pending, open a draft PR and state the pending verification explicitly.
- When resuming an empty unpublished branch, advance its ref to the fetched base before switching, after
  checking ancestry and preserving stashes, or create a fresh branch at that base. Avoid checking out an old
  tree and then fast-forwarding: that touches unchanged source and headers and invalidates incremental builds.
- Verify changes only with `python -B tools/verify_all.py` ([guide](../../docs/coa/verification.md)). It runs the
  source checks, build, unit tests, Python test scripts, `apps/coa-tests` harnesses and gameplay scenarios. Do not
  run `check_source.py`, `ctest`, test scripts, harnesses, `run.py run` or `batch.py` yourself; where a guide
  names one, use the matching selection (`--stages harness --harness <name>`, `--stages source`).
- The one exception is proof that `verify_all.py` cannot run: Ghost e2e tests (real sessions) and client checks
  (rendered UI) run as `.agents/skills/coa-development/references/guide-tooling.md` describes, only when a
  gameplay scenario cannot observe the behavior. They add to the `verify_all.py` stages the change requires and
  never replace them; report them separately, with the tested server commit.
- Verify the tests the change adds or modifies: pair `--stages` with a focus filter
  (`--scenario`/`--spell`/`--quest`/`--query`, `--harness`) and include `build` whenever sources changed. Before a
  PR, also run `python -B tools/verify_all.py --stages source --base origin/main`. Run every stage
  (`python -B tools/verify_all.py --base origin/main`) only when full verification is explicitly requested.
- Re-run only what a change can reach: read `git diff --stat <measured commit>..HEAD` first. Documentation,
  `.agents/` or plan changes need no gameplay rerun; a narrow fix reruns its scenarios and those sharing the
  touched spell, aura or stat path; a shared core file (`Unit.cpp`, `StatSystem.cpp`, `SpellMgr`, …) reruns the
  affected suite.
- Leave `--jobs` unset: the default is the CPU count, and fewer jobs only slow the build (a measured replay of
  1,416 compiles took 700 s at `--jobs 6` against 549 s at 10 or 14).
- The `codestyle-cpp.py`/`codestyle-sql.py --files` linters are separate; still run them on changed C++ and SQL.
- Report the final `VERIFY ALL: PASSED|FAILED|INCOMPLETE` line with its `report.json`, the stages that ran,
  unavailable or blocked scope with reasons, and any `batch_sensitive` scenarios. Only `PASSED` is a pass, and
  only for what ran. A failure in the verified tests blocks a PR. A requested full run is not yet all green on
  any setup; classify each failure or unavailable item as a documented prerequisite, pre-existing on the base,
  acceleration-specific (a real-clock reference run passes it) or new
  ([full runs](../../docs/coa/verification.md#full-runs)).
- Gameplay verification runs accelerated only by default: fix fast failures before accepting a batch.
  Slower same-server retries require `--gameplay-real-pace-rerun`; report their `acceleration_sensitive` ids as
  diagnostic-only passes. A passing retry alone does not prove a clock dependency. Confirm a repeatable timing
  defect with a focused `--gameplay-clock real` reference while repairing it, then use accelerated verification
  ([accelerated mode](../../docs/coa/verification.md#accelerated-single-server-mode)).
- A probabilistic assertion (a 20% proc, a crit-gated effect) is a coin flip, not a test: force the condition or
  drive enough trials that the residual failure probability is negligible, and state it in the scenario contract.
- `run.py validate`, `catalog.py` and `workflow.py` remain authoring and discovery tools, not verification.
