---
name: coa-gameplay-test
description: >-
  Design CoA worldserver scenarios and verify them through tools/verify_all.py to test spells, talents, items and
  server-side effects. Use for requested gameplay/runtime validation; source-only edits and rendered client/UI
  testing have separate scopes.
---

# CoA gameplay test

Use the gameplay harness in `C:/Ascension/azerothcore-wotlk-coa`, or the user's explicitly selected CoA checkout.
Read that checkout's `AGENTS.md`, `apps/coa-gameplay-test/README.md` and `docs/coa/verification.md` before the
first run. Execute scenarios only through `tools/verify_all.py`; do not launch `run.py run` or `batch.py` directly.
The Docker Compose service in the README is the only other route: use it only when the user asks for it on a
Docker-only installation, inspect its run directory as the README's Docker section describes and report its
results as single-scenario evidence.

## Establish the experiment

- Translate the requested behavior into actions and independent expected results. For Ascension scaling,
  triggered spells or tooltip parity, use `.agents/docs/systems/ascension-spell-parity.md` to establish the
  contract. A calculation copied from the current implementation is not independent evidence.
- Start from `apps/coa-gameplay-test/scenarios/frostbolt.json`. Use the scenario actions and metrics actually
  supported by the README. Name actors, snapshots and assertions clearly. Store a new reusable regression
  in the scenario directory when it belongs to the requested change; use `.cache/coa-gameplay-tests/` for
  an exploratory scenario.
- Configure level, equipment, learned abilities and target conditions explicitly. A `learn` action is fixture
  setup; use `talent` to exercise talent point/prerequisite checks. A normal `cast` or `use_item` submission
  requires effect assertions to prove behavior. Keep normal costs, cooldowns and proc rules enabled.
- Check passive talents with `has_talent` using their rank's spell ID; they are stored separately from
  learned spells. Check `talent_points` for point consumption and use `reset_talents` for fixture removal.
- `within_ms` means eventually true. To prove an effect does not occur, wait through its possible trigger
  window before checking absence. Net health/power deltas include regeneration and other effects. Random
  proc rates require repeated trials and a statistical check beyond this harness's built-in assertions.
- Let spawn AI and level scaling settle before measuring damage. Verify stable maximum health and take a
  fresh health baseline before each tested cast. Prepare equipment while the actor is out of combat.
- The gameplay stage runs up to 15 scenarios at once in one worldserver on a simulated clock. Keep timing
  assertions robust to one world step (up to 25 ms in a `wait`, 10 ms while polling `within_ms`). Refer to players
  by actor id: `Harness<a..h>` is rewritten only in `console` and `command` text, and explicit fixture names are
  not made unique per lane. A `set_phase` mask that includes the normal world phase (mask 1) automatically makes
  the scenario exclusive, including exploratory scenarios. Other process-global state (such as the Who list)
  needs an entry with its reason in `apps/coa-gameplay-test/clock_policy.json`. Creature text with area, zone or
  map range crosses phases and counts in `system_messages`, so an exact delta can pick up another lane's
  creature on the same map.

## Execute

1. Validate the scenario while writing it with `python apps/coa-gameplay-test/run.py validate <scenario>`.
2. Check the settings with `python -B tools/verify_all.py --plan`. It resolves the worldserver, its config, the
   local MySQL 8 client tools and the server modules directory from `conf/verify-all.json` or auto-detection and
   shows them without secrets. Never print credentials. If normal credentials cannot create schemas, set
   `database_client_config` to an authorized existing MySQL `[client]` file on the same endpoint (see the
   gameplay README). Do not change existing account grants.
3. Run `python -B tools/verify_all.py --stages build,gameplay --scenario <id-or-path>` (or `--spell`, `--quest`,
   `--query`). The build stage compiles the checkout, so the gameplay stage tests current edits; keep the build's
   worldserver as the gameplay binary. A requested runtime run permits the isolated `coa_test_*` database
   copies and owned test processes; it does not authorize replacing the installed server, and `verify_all.py`
   never installs. A scenario path that differs from its catalog definition runs as exploratory native
   execution only, without combined verification; a selection of such files only ends `INCOMPLETE` even when
   they pass.
4. Inspect `report.json`, then `gameplay/gameplay.json`, `gameplay/verification.json`, the case bundle
   (`summary.json`, `result.json`) and the server logs in `gameplay/servers/`. `cases.<id>.directory` in
   `gameplay.json` names the bundle that decided a catalog case's verdict: `gameplay/cases/<id>/` for the
   queue-mode or accelerated attempt, `gameplay/real-pace/<id>/` for a real-pace rerun (an
   `acceleration_sensitive` id's passing bundle) or `gameplay/isolated/<id>/`; the other attempts are nested
   under `batch`, `real_pace` or `isolated`. An exploratory file is in `gameplay/exploratory/<key>/`, keyed by
   its file name, and each worker's runner output is in `gameplay/logs/slot-<k>.log`. A pass requires
   `VERIFY ALL: PASSED` (exit 0), a passed case and passed combined verification. Missing readiness, a crash, a
   partial result, a timeout, or a `not_run` or `cleanup_failed` case is a failed run; `INCOMPLETE` names a
   missing prerequisite; exit code 2 means the invocation or settings were invalid and nothing ran. Diagnose
   infrastructure failures before interpreting gameplay outcomes. Use a new run after a correction; each run
   writes a new output directory, preserving evidence of the failed attempt.
5. The default stage runs accelerated only: a fast failure remains failed. Inspect the native result, verify
   the authored contract, and repair the mechanic or fixture before another accelerated run. Random failures
   need enough eligible trials and a statistical check; a passing retry alone is not a timing diagnosis.
   `--gameplay-real-pace-rerun` explicitly opts into slower same-server diagnostics and reports ids passing only
   there in `acceleration_sensitive`; these are diagnostic-only passes, not clean accelerated passes. Read the
   accelerated attempt (`cases.<id>.batch.message`) first: `Worldserver exited` or a case timeout means a crash or
   hang. Confirm an actual repeatable clock dependency with a focused `--gameplay-clock real` reference during
   its repair. Use accelerated verification for normal batches afterward.
   On the real clock, a `batch_sensitive` id failed in the batch but passed an isolated rerun. An `isolated_only`
   id passed only in its rerun without a batch failure verdict. Report their limited scope accurately. A contract
   requiring specific configuration needs matching settings; one configuration cannot satisfy every catalog
   scenario (`docs/coa/verification.md`, Full runs).
6. Check `world_cache` in the summary: a retained, verified world is intentional, and each gameplay worker (one
   on the simulated clock) has its own slot under `.cache/coa-gameplay-tests/world-cache/slots/`. A scenario that
   writes world data discards that slot's copy after its server stops, and later cases on that server see the
   write. Source SQL outside the fingerprinted directories is not detected. A slot lease blocks concurrent users;
   run one gameplay stage at a time and do not remove a lease until its runner and worldserver are confirmed
   stopped.

## Report

State the tested scenario, actual versus expected results, executable identity and any untested behavior.
Give the `VERIFY ALL` status line, the stages that ran, the gameplay clock, unavailable scope and
`acceleration_sensitive` and `batch_sensitive` ids, and link the result files. Distinguish validation of the
runner from execution of the native scenario.

This mode uses real game objects and character loading with socketless sessions. It does not cover network
authentication/session discovery, client packet delivery, rendered tooltips, animations or UI input.
Do not claim those were tested. Add a supported driver or a separate client test when the task requires them.
