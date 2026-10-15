# Verification

`tools/verify_all.py` is the single verification command for this repository. It runs the fast source checks,
builds the checkout, runs the Google Test unit tests, every Python test script and `apps/coa-tests` harness,
then verifies the catalog gameplay scenarios in one accelerated worldserver. The scripts it calls (`check_source.py`,
`ctest`, the harness scripts, `apps/coa-gameplay-test/batch.py` and `run.py`) are its implementation; verify
through `verify_all.py` rather than launching them one by one.

```sh
python -B tools/verify_all.py --plan
python -B tools/verify_all.py
```

It never installs, deploys or replaces an installed server. Test worldservers use only disposable or cached
`coa_test_*` schemas, and database passwords never appear in its console output, plan or reports.

## Setup

Requirements are those of the parts that run: CMake and a C++20 toolchain (Ninja is used when present),
Python 3.11+, a local MySQL 8 server with its `mysql`/`mysqldump` client tools, the server's worldserver
config and the client DBCs described in [the CoA README](README.md#client-dbcs).

Settings live in the optional, gitignored `conf/verify-all.json`; `--settings <file>` selects another file.
Every key is optional, unknown keys are an error and relative paths resolve against the repository root.
Keep secrets out of this file: credentials stay in the worldserver config or the MySQL client file.

```json
{
  "build_directory": "build",
  "worldserver_config": "/path/to/etc/worldserver.conf",
  "modules_config_dir": "/path/to/etc/modules",
  "mysql": "/opt/homebrew/opt/mysql-client/bin/mysql",
  "mysqldump": "/opt/homebrew/opt/mysql-client/bin/mysqldump",
  "database_client_config": "/path/to/admin-client.ini",
  "dbc_directory": "env/dist/data/dbc"
}
```

| Key | When unset |
| --- | --- |
| `build_directory` | `build` |
| `cmake_args` | the configuration shown below |
| `worldserver` | the newest executable named `worldserver` inside the build directory |
| `worldserver_config` | `<CONF_DIR>/worldserver.conf` (see below) |
| `server_modules_dir` | outside Windows, `<CONF_DIR>/modules`, where the worldserver reads module configs |
| `modules_config_dir` | the runner's default, `modules/` beside the worldserver config |
| `mysql`, `mysqldump` | `PATH`, then `/opt/homebrew/opt/mysql-client/bin` and `/usr/local/opt/mysql-client/bin` |
| `database_client_config` | none; the worldserver config's credentials are used |
| `dbc_directory` | the first of `COA_DBC_DIR`, `<DataDir>/dbc` and `env/dist/data/dbc` that holds `Spell.dbc` |
| `workspace_tools` | `<repo>/../tools`; used only for scripts that declare `--workspace-tools` |
| `datamine_directory` | none |
| `mysql_server_bin` | none; a MySQL `bin` directory holding both `mysql` and `mysqld`, for `--mysql-bin` |
| `jobs` | the CPU count |
| `gameplay_jobs` | `max(1, min(4, cpu // 3))`; used only with `--gameplay-clock real` |
| `gameplay_db_workers` | `16` (1-32); character database workers, used only with the simulated clock |

`cmake_args` is used only to configure a build directory that has no `CMakeCache.txt` or whose last configure
did not generate build files. Its default adds `-G` with the generator already in the cache, else `-G Ninja`
when ninja exists:

```sh
-DCMAKE_BUILD_TYPE=RelWithDebInfo -DAPPS_BUILD=world-only -DSCRIPTS=static -DMODULES=static
-DBUILD_TESTING=ON -DCMAKE_INSTALL_PREFIX=<repo>/env/dist
```

On macOS the default also passes `-DREADLINE_LIBRARY` and `-DREADLINE_INCLUDE_DIR` for Homebrew readline when it
is installed; without them CMake finds the SDK's libedit stub and the worldserver does not compile. It also sets
`CMAKE_C_FLAGS_RELWITHDEBINFO` and `CMAKE_CXX_FLAGS_RELWITHDEBINFO` to `-O2 -g1 -DNDEBUG` (Clang treats `-g1` as
`-gline-tables-only`, and GCC accepts it too): object files shrink by an order of magnitude and archives and links
get faster, while crash backtraces keep file and line but lose class names and arguments. A `cmake_args`
setting replaces all of these defaults, so repeat the flags there when they are wanted.

The macOS CMake configuration also creates static libraries with `/usr/bin/libtool -static` instead of
`ar` and `ranlib` (Ninja and Makefile generators; a cached `CMAKE_CXX_CREATE_STATIC_LIBRARY` overrides it), and
`coa` and `modules` reuse the precompiled header of `game` when `USE_COREPCH` is on and the compiler is Clang.

- `CONF_DIR` is a `CONF_DIR` entry of the build's CMake cache when present, else `<CMAKE_INSTALL_PREFIX>/etc`.
  On Windows it is the `configs/` directory beside the worldserver, else `<CMAKE_INSTALL_PREFIX>/configs`.
- Keep the default `worldserver` so the gameplay stage tests the binary the build stage just compiled. An
  installed server can be older than the checkout. With a multi-config generator, the worldserver of the
  cached `CMAKE_BUILD_TYPE` (default `RelWithDebInfo`) is preferred.
- The worldserver config is read, never changed. On Windows, set `mysql` and `mysqldump` to the `.exe` paths
  unless they are on `PATH`.
- A `dbc_directory` setting is used as given. Otherwise the candidates are tried in the order of the table: an
  inherited `COA_DBC_DIR`, then `dbc/` under the worldserver config's `DataDir` (a relative `DataDir` resolves
  against the worldserver's directory), then `env/dist/data/dbc` in the checkout. Only a candidate holding
  `Spell.dbc` is taken, so a stale `COA_DBC_DIR` wins over the config; set `dbc_directory` to be explicit.
- `database_client_config` is the existing MySQL `[client]` file described in the
  [gameplay README](../../apps/coa-gameplay-test/README.md#run), for accounts that cannot create schemas.
- During a run the gameplay stage copies the source module `.conf` files into the server modules directory and
  removes them afterwards. That directory must not hold `.conf` files of its own (`.conf.dist` files are
  ignored), so keep the source module configs in another directory, beside another worldserver config or in
  `modules_config_dir`.

Run `--plan` after changing settings. It prints the resolved stages, commands, harness classification, scenario
count and settings (without secrets) as JSON, and exits 0 without running anything. For the source stage it shows
only the `check_source.py` command; the suites that command selects appear in `report.json` and `source.log`
after a run.

### Separate worktrees

`conf/verify-all.json`, the `build` directory, relative settings paths and the world-cache slots all resolve
inside the checkout that runs `verify_all.py`, and the first two are gitignored. A new worktree therefore has
no settings and no build: pass `--settings <file>` with absolute paths for the worldserver config, MySQL tools
and DBC directory, and expect a full first build and new world-cache copies. Keep the worktree's own
`build_directory`; a build directory configured for another checkout compiles that checkout's sources. The
worktree's worldserver reads module configs from its own `<CONF_DIR>/modules`, so create that directory or set
`server_modules_dir` to it. Run `--plan` in the worktree to see what is still missing, or verify from the
primary checkout when that is possible.

## Stages

Stages run in this order. Each reports `passed`, `failed`, `unavailable` (a prerequisite is missing),
`blocked` (the build failed) or `skipped` (not selected).

1. `source`: `tools/check_source.py`, which covers SQL boundaries, comments in CoA-owned code, loader
   registrations and the tooling test suites. See [Source comparison base](#source-comparison-base).
2. `build`: configures a build directory as described for `cmake_args`, reconfigures one that has
   `BUILD_TESTING` off with `-DBUILD_TESTING=ON`, then runs `cmake --build <build> --parallel <jobs>` (with
   `--config` for a multi-config generator). The directory holding `mysql_config` is put first on `PATH`.
3. `unit`: `ctest --test-dir <build> --output-on-failure --parallel <jobs> --no-tests=error` (with `-C` for a
   multi-config generator). Blocked when the build failed; `unavailable` without a configured test build.
4. `harness`: every `apps/coa-tests/*/run.py` and every `test_*.py` outside the `tools/check_source.py` suites
   that Git tracks or would add (untracked files count unless ignored), in parallel, with a 900-second limit
   each and `COA_DBC_DIR` set when a DBC directory is known. An untracked scratch test in the checkout runs too.
   See [Harness prerequisites](#harness-prerequisites).
5. `gameplay`: `apps/coa-gameplay-test/batch.py` in [queue mode](#gameplay-queue-mode): one worldserver on a
   simulated clock, or `gameplay_jobs` real-clock worldservers with `--gameplay-clock real`. Blocked when the
   build failed. It is `unavailable`, naming the reason, when the worldserver,
   its config, `mysql`, `mysqldump` or (outside Windows) the server modules directory cannot be found, when a
   configured `database_client_config` or `modules_config_dir` does not exist, when the config's `DataDir` has
   no `dbc/Spell.dbc`, when the server modules directory already holds `.conf` files, and when the selection
   held only exploratory scenario files (they ran and passed natively, without combined verification).

Stages that need the build (`unit`, `gameplay`) are `unavailable` when the build stage was unavailable.

The build stage does not reconfigure an existing build for other reasons. After adding a source file that needs
CMake discovery, reconfigure the build directory as described in `.agents/docs/build.md`.

### Source comparison base

- Without `--base`: `check_source.py --all` runs every fast suite and checks comments in every CoA-owned C++
  and Python file, but compares changed files, and therefore SQL boundaries, with `HEAD`: only uncommitted and
  untracked changes.
- With `--base <ref>`: `check_source.py --base <ref>` runs the suites that the diff against `<ref>` selects
  (staged and untracked files included), checks comments on the lines added since `<ref>` and checks SQL
  boundaries for the whole diff.

Without `--base`, a change that is already committed is not boundary-checked: a committed edit under
`data/sql/base/` passes. Before a PR, pass the PR base (`--base origin/main`); that is the selection CI uses
for a pull request. `report.json` (`selected_suites`, `failed_commands`) and `source.log` show what ran.

## Focused runs

`--stages` and `--skip` take comma-separated stage names. A focus filter narrows only its own stage and does not
disable the others, so pair it with `--stages`; a filter for a stage that is not selected is ignored:

- `--scenario ID_OR_PATH ...`: catalog ids or scenario files for the gameplay stage. A file identical to a
  catalog definition counts as that catalog id. Any other valid scenario file is exploratory: it runs natively
  only, is reported separately, is excluded from registered numerical checks and is never labeled combined
  verification. It must still pass for the gameplay stage to pass, and a selection of exploratory files only
  leaves the stage `unavailable` (`INCOMPLETE`) even when they pass.
- `--spell ID`, `--quest ID`, `--query TEXT`: select gameplay scenarios through the catalog, as
  `apps/coa-gameplay-test/catalog.py` does.
- `--harness NAME ...`: harness scripts by directory name or file stem.
- `--base REF`: the source stage compares with `REF` instead of `HEAD` and runs only the suites that diff
  selects; see [Source comparison base](#source-comparison-base).

- `--fresh-databases` or `--refresh-world`: the gameplay stage uses disposable database copies instead of the
  world-cache slots, or replaces each slot's world copy on first use.
- `--gameplay-clock simulated|real` (default `simulated`), `--gameplay-lanes N` (1-15, default 15, simulated
  only) and `--gameplay-db-workers N` (1-32, default `gameplay_db_workers`, simulated only): see
  [Gameplay queue mode](#gameplay-queue-mode) and [Character database](#character-database).

Companion scenarios required by a registered numerical check are added to any gameplay selection. All selected
definitions are validated before a server starts. `--jobs N` sets build, unit and harness parallelism;
`--gameplay-jobs N` sets the number of real-clock worldservers. When the gameplay stage is selected, a
`--gameplay-jobs` above 1 is rejected with the simulated clock and a `--gameplay-lanes` or
`--gameplay-db-workers` above 1 with the real clock; the `gameplay_jobs` setting applies only to the real clock and
`gameplay_db_workers` only to the simulated clock.

```sh
python -B tools/verify_all.py --stages source --base origin/main
python -B tools/verify_all.py --stages build,gameplay --scenario primalist-everlasting-rage
python -B tools/verify_all.py --stages build,gameplay --spell 1257670
python -B tools/verify_all.py --stages harness --harness primal_weapons test_automatic_talent_dependencies
```

A stage left out by `--stages` or `--skip` does not run, so include `build` whenever sources changed; otherwise
the gameplay and unit stages test whatever binaries already exist. Before a PR, or when a full verification is
requested, run every stage without focus filters and with the PR base:

```sh
python -B tools/verify_all.py --base origin/main
```

Such a run does not currently end `PASSED`; see [Full runs](#full-runs) for how to read it.

## Results and exit codes

Output defaults to a new `.cache/verify-all/<UTC YYYYmmdd-HHMMSS>/` directory (with a `-2`, `-3` suffix when
that exists); `--output DIR` selects another, which must be new or empty.

- `report.json`: `schema`, overall `status`, `stages` (each with `status`, `seconds`, `summary` and `log`), the
  resolved settings (paths only), `output` and the total `seconds`. The gameplay summary repeats the batch
  `counts`, the `verification` status, `clock`, `lanes`, `failed_cases`, `acceleration_sensitive`,
  `batch_sensitive`, `isolated_only`, `exploratory` and the `batch_failures` that belong to no case.
- `<stage>.log`: the output of each stage.
- `gameplay/`: the gameplay stage's result tree, described below.

The console prints one line per stage and finishes with `VERIFY ALL: PASSED|FAILED|INCOMPLETE <report path>`.
The gameplay line also names the clock, the lanes and the number of acceleration- and batch-sensitive cases.

| Exit code | Final line | Meaning |
| --- | --- | --- |
| 0 | `PASSED` | Every selected stage passed. |
| 1 | `FAILED` | A stage failed or was blocked. |
| 2 | none | Invalid invocation or settings; nothing ran and no `report.json` exists. |
| 3 | `INCOMPLETE` | Nothing failed, but a stage or an individual harness script was unavailable. |

An exploratory-only gameplay selection counts as an unavailable stage.

`INCOMPLETE` is not a pass: report what was unavailable and why. A `PASSED` focused run covers only the stages
and selections that ran; state that scope when reporting it. Exit code 2 is not a verification result: it
prints only an `ERROR:` line, for example for unknown or invalid settings keys, a non-empty `--output`, a
`--scenario` that is neither a catalog id nor a file, a `--harness` name that matches no script or a
`--spell`/`--quest`/`--query` that matches no scenario. Correct the invocation and run again.

The gameplay result tree contains:

- `gameplay.json`: `status`, `scope`, `selected`, `exploratory`, `jobs`, `clock`, `lanes`, `binary`,
  `binary_sha256`, `counts` (`passed`, `failed`, `not_run`, `passed_on_isolated_rerun`), `cases`,
  `acceleration_sensitive`, `batch_sensitive`, `isolated_only`, `exploratory_results`, `servers`,
  `verification` (`status`, `failures`, `checks`), `failures` (batch failures that belong to no case),
  `interrupted` and `seconds`. The simulated clock adds game and real elapsed totals (`game_elapsed_ms`,
  `real_elapsed_ms`) and `simulation` (`step_ms`, `active_wait_cap_ms`, `poll_cap_ms`, `start_hour`,
  `character_db_workers`, `character_db_isolation` and the `exclusive` ids). `status` is `passed` only when
  combined verification passed, every selected case, exploratory ones included, passed and `failures` is empty;
  a selection of exploratory files only reports `exploratory` when they all passed.
- `cases` in `gameplay.json`: per id, the attempt that decided the verdict (`status`, `mode`, `directory`,
  `message`, `seconds`), which is the passing attempt, else the first one that left a bundle. Its other
  attempts are nested under `batch` (the queue-mode or accelerated attempt), `real_pace` or `isolated`. A
  case's `mode` is `batch`, `single` or `isolated` on the real clock and `simulated`, `real_pace` or `isolated`
  on the simulated clock. `directory` names the bundle that combined verification used: for an
  `acceleration_sensitive` id it is under `real-pace/`, not `cases/`. An attempt that ran records its
  `realm_local_start`, and a single-mode run or rerun of a case with an `hour` its `timezone` (see
  [Realm-local time](#realm-local-time)).
- `verification.json`: combined verification of every selected catalog case and its companions.
- `cases/<id>/`: the queue-mode or accelerated attempt: `scenario.json`, `result.json` and a `summary.json`
  compatible with `apps/coa-gameplay-test/verification.py`, plus `batch` (`id`, `slot`, `sequence`,
  `server_directory`) and, on the simulated clock, `simulation` (`lanes`, `pace`, `exclusive` and the measures
  below). `result.json` records the `realm_local_start` and, on the simulated clock, the `clock`, `lane`,
  `phase_mask`, `game_elapsed_ms`, `real_elapsed_ms`, `setup_real_ms`, world `ticks` and `max_step_ms`, the
  largest world step while the case ran. On the real clock, a case with an `hour` leaves its single-mode bundle
  here instead.
- `real-pace/<id>/`: the same bundle for a case's
  [optional real-pace diagnostic](#accelerated-verdicts-and-optional-diagnostics) on the simulated clock.
- `exploratory/<key>/`: the same bundle for an exploratory scenario file. `<key>` is the file name without
  `.json`, lowercased with other characters replaced by `-` and a `-2`, `-3` suffix for repeated names. Its
  progress line reads `exploratory:<key>` and its `exploratory_results` entry is keyed `<key>`.
- `servers/slot-<k>-<n>/`: one directory per started worldserver (`n` counts the restarts of worker `k`, from
  1), with its logs, ready/start files, `cases/case-<sequence>.json` files, a `requeued/<id>/` bundle for a case
  it lost and queued once more, and a `summary.json` (status, exit code, cases, restarts, world cache, cleanup
  result, binary hash and timings).
- `isolated/<id>/`: single-scenario rerun bundles.
- `logs/slot-<k>.log`: the standard output of worker `k`, including its isolated reruns.

The batch runner's own output goes to `gameplay.log`: `PASS <id> <seconds>` or `FAIL <id> <seconds>` for each
finished case (suffixed `real-pace` or `isolated` for a rerun, `single` for a real-clock case with an `hour`,
`not run` or `cleanup` for those failures), `REQUEUED` and `SERVER <name> FAILED` lines, and a final
`GAMEPLAY PASSED|FAILED|EXPLORATORY` line naming `gameplay.json`. Its exit code is 0 for `passed`, 3 for
`exploratory`, 1 otherwise and 130 when it was interrupted before writing `gameplay.json`.

## Gameplay queue mode

The gameplay stage does not start one worldserver per scenario. A queue-mode worldserver
(`CoAGameplayTest.CaseDirectory`) runs many scenarios, taken from one queue ordered by estimated duration,
longest first. The server needs the queue-mode runtime of the current source; the build stage provides it.

- `--gameplay-clock simulated` (default): one worldserver runs up to `--gameplay-lanes` cases (default 15) at
  once on a simulated clock; see [Accelerated single-server mode](#accelerated-single-server-mode).
- `--gameplay-clock real`: each of the `gameplay_jobs` workers starts a worldserver that runs one case at a time
  on the real clock, followed by [isolated reruns](#isolated-reruns-and-batch_sensitive). This is the
  [real-clock reference](#real-clock-reference-runs).

### Accelerated single-server mode

Each running case owns a lane. The runner keeps up to twice as many case files written ahead as there are lanes,
and the server admits the next file whenever a lane is free.

- Players and fixture creatures of a lane use its own phase: bit 30 for lane 0 and bits 16-29 for lanes 1-14.
  `set_phase` without a `value` uses the lane's phase.
- With more than one lane, default character names are generated 10-letter names (`H` followed by alternating
  consonants and vowels), and whole-word `Harness<a..h>` in `console` and `command` text becomes the case's
  generated name. Explicit fixture `name` values are kept.
- Proc counters and regeneration suppression belong to the case's characters, and a case failure affects only its
  lane. Protocol and teardown violations still stop the server.

Game time advances in steps instead of following the wall clock. After each world update every running lane
states the step it needs, and the smallest one is taken, clamped to 1-2000 ms:

| Lane state | Step |
| --- | --- |
| Runs a non-wait step, has actors in the world that are not all ready, or awaits database work | 3 ms |
| Inside a `wait` | the time left, at most 25 ms |
| Polls a failing `within_ms` assertion | the window left, at most 10 ms |
| Idle, tearing down, or no actor in the world yet | none |

Database work means pending harness queries or callbacks on the case's sessions. When no lane needs a step, the
world runs paced at real speed. The harness does not order asynchronous database writes against later synchronous
reads: consecutive steps take far less real time than on the real clock, so game code that reads back its own
fire-and-forget write without waiting for it fails there, as it can in production under database load. The caps are
the `batch.py` defaults (`--step-ms`, `--active-wait-cap-ms`, `--poll-cap-ms`), which `verify_all.py` does not
change. `wait`, `within_ms` and step `elapsed_ms` use game time on both clocks; on the real clock it follows the
wall clock at world-tick resolution. `timeout_ms` covers the real setup time until every actor is ready plus the
game time after that, and the server fails a case that runs three times `timeout_ms` of real time from admission.
The runner treats a case as hung `3 * timeout_ms / 1000 + 60` seconds after a lane could first have admitted it, not
after it wrote the file ahead: the count starts once the case is among the first `lanes` unfinished case files and
no exclusive case keeps it waiting (an exclusive case counts only once it is the first).

### Fidelity limits

A simulated verdict can differ from a real-clock one for these reasons:

- Tick caps: one world update covers up to 25 ms of game time in a wait and 10 ms while polling, and creatures,
  game objects and dynamic objects update at most once per `MapUpdateInterval`, with the accumulated time.
  Swings, periodic ticks, AI timers and expiries can land up to one step late, and measured durations are only
  as precise as the step.
- Raw clocks: `getMSTime()`, game time and the proc internal cooldowns follow the simulated clock. Code that reads
  the wall clock directly (`GetTimeMS()`, `steady_clock::now()`, `system_clock::now()`, `time(nullptr)`,
  `TaskScheduler::Update()` without a diff, `TaskScheduler::GetNextGroupOccurrence()`, MySQL `NOW()`) does not,
  and the game's calendar time starts at the [start hour](#realm-local-time) and runs ahead of the wall clock by
  the time skipped. The LFG raid browser compares
  game time with the wall clock to detect lag, so it stops refreshing once they differ by more than 98 ms.
- Shared process: concurrent cases share one worldserver. Phases separate only phased objects; process-global
  state (the Who list, configuration, caches, script globals and the world database) is visible to every
  running case. `system_messages` counts every chat line a session receives, and creature text with area,
  zone or map range reaches every player on that map whatever their phase, so another lane's creature can
  change an exact `system_messages` delta. Broadcasts sent through the session manager, such as world
  announcements, do not reach the harness sessions, which it does not hold.
- Character database: the simulated-clock worldserver writes through several character database workers at
  `READ-COMMITTED`, so asynchronous character writes can commit out of queue order, and a reader sees rows that
  other transactions committed meanwhile. See [Character database](#character-database).
- Lost servers: a crash or hang with several cases running, or after an earlier case on that server returned
  its result, fails the batch. With one case running on a server that has not returned a result yet, it fails
  only that case. A real-pace retry is available only through the explicit diagnostic option. See
  [Server failures](#server-failures).

### Accelerated verdicts and optional diagnostics

The normal gameplay stage runs accelerated only. A failed or not-run catalog case remains failed, and a passing
case has `mode: simulated`. The runner does not turn a failed accelerated attempt into a pass through a slower
retry. Repair the failed mechanic, fixture or independent expectation and run a new accelerated verification.

For a controlled comparison, `verify_all.py --gameplay-real-pace-rerun` explicitly enables slower same-server
diagnostics after the accelerated queue. The underlying runner option is `batch.py --real-pace-rerun`; continue
to execute verification through `verify_all.py`. Each failed catalog case then runs with `pace: real`: while it
runs no lane requests clock steps. A case passing this diagnostic has `mode: real_pace` and appears in
`acceleration_sensitive`. Report it as a diagnostic-only pass, not a clean accelerated pass. `batch.py
--isolated-rerun` separately opts into single-mode reruns; the regular simulated `verify_all.py` invocation
enables neither slower path.

A failed accelerated attempt followed by a passing retry does not by itself establish timing sensitivity.
Independent random hit/proc rolls and invalid fixture assumptions can produce the same pattern. First inspect
`cases.<id>.batch` and the original contract. A `Worldserver exited` or timeout message is a crash or hang to
repair. For deterministic behavior, configure hit/expertise ratings and equipment explicitly; for random procs,
collect enough eligible native events and use a statistical check. Preserve normal costs, cooldowns and proc
rules. Only a repeatable controlled comparison supports a clock dependency; use a focused
[real-clock reference run](#real-clock-reference-runs) while repairing one. Normal issue-batch verification
uses the accelerated path.

With multiple character database workers, a controlled `--gameplay-db-workers 1` run can distinguish write
ordering from game-clock timing. A `clock-*` scenario failing accelerated indicates a simulated-clock defect;
a slower diagnostic pass cannot establish that the clock works. Keep its accelerated failure explicit.

### Exclusive cases

`apps/coa-gameplay-test/clock_policy.json` lists the cases that must not share the server with another running
case, each with its reason:

```json
{"schema": 1, "exclusive": {"who-lists-bots": "Who list is process-global"}}
```

An exclusive case is admitted only when every lane is idle, and no other case starts until it finishes. The runner
rejects ids missing from the catalog and empty reasons. The list holds `who-custom-classes`, `who-hides-bots` and
`who-lists-bots` (the Who list is process-global) and `bloodforged-high-risk-drop` and
`coa-prestige-chromie-spawns` (`set_phase 1` affects live creatures) and `wildcard-season-event` (it stops the
Wildcard season game event). A case with an [`hour`](#realm-local-time) or a `set_phase` step whose mask includes
the normal world phase (mask 1) is exclusive without being listed. The phase rule also applies to exploratory
scenarios. Add a case, with its reason, when it reads or changes other process-global state;
exclusivity does not fix timing failures. Chat that ignores
phases is a known limit that the list does not cover: `treasure-keeper` asserts exact `system_messages` deltas and
shares the server, so [creature text on its map](#fidelity-limits) from another lane can fail it.

### Realm-local time

Some mechanics read the realm-local hour from game time, in the worldserver's `TZ`. A scenario that needs a part
of the day sets a top-level `hour` (0-23), and `realm_local_start` in each result shows the game time, as
`YYYY-MM-DD HH:MM:SS`, at which the case started.

- Simulated clock: realm-local time starts at the next 10:00 that is not in the past
  (`CoAGameplayTest.StartHour`), so cases without an `hour` run at a known time of day. A case with an `hour` is
  exclusive and queued after the others. Unless realm-local time is already in that hour's first minute, the
  server moves every game clock ahead to the next `hour`:00 while no case runs, without a world update for the
  skipped time, and then starts the case. The next case without an `hour`, such as a real-pace rerun, moves the
  clocks ahead to the next start hour the same way, unless realm-local time is already in it. Daily, weekly and
  monthly quest resets and the battleground, calendar and guild resets are scheduled from game time, so a move
  past a reset time runs that reset once.
- Real clock: the runner runs a case with an `hour` in single mode after the queue, on a worldserver whose `TZ`
  is a fixed offset, to the minute, that puts local time at the start of that hour when the runner starts the
  worldserver, for example `UTC+10:40` at 22:40 UTC for `hour` 12 (POSIX inverts the sign). The rest of the hour
  covers startup. Single-mode reruns on either clock do the same. Queue-mode worldservers keep the caller's `TZ`
  and fail a case whose `hour` is not the current local hour.

### Real-clock reference runs

Use a focused real-clock reference to investigate a repeatable timing discrepancy or a change to timers,
the world update loop or the harness clock. Rule out random hit/proc outcomes and missing prerequisites first.
Normal verification remains accelerated only; a slower reference does not qualify a failed fast batch:

```sh
python -B tools/verify_all.py --stages build,gameplay --gameplay-clock real --scenario <id>
python -B tools/verify_all.py --base origin/main --gameplay-clock real
```

It runs `gameplay_jobs` (or `--gameplay-jobs`) worldservers on the real clock, one case at a time each, then
isolated reruns. A `--gameplay-lanes` above 1 is rejected with it. Both clocks run the same harness: `wait`,
`within_ms` and step `elapsed_ms` measure game time, which on the real clock follows the wall clock at world-tick
resolution, and the login barrier and same-tick setup apply on both. A failure that both clocks show can
therefore come from the harness as well as from the change. When the two clocks disagree on a case,
report both outcomes and repair the discrepancy. A slower pass does not qualify a failed accelerated batch.

### Per-case isolation

- Each case gets its own run id and new accounts (`CT<run id><index>`). With one lane, character names are the
  same as in a single run (`Harness<a..h>` or the fixture `name`), because scenarios refer to them.
- On the real clock, the scenario's `timeout_ms` counts from the moment the server picks up the case, and the
  runner allows `timeout_ms / 1000 + 60` seconds before it treats the case as hung.
- Invalid scenario data fails only that case. Proc counters, regeneration suppression, snapshots, actors and
  every other per-scenario record start empty for each case.
- After every case, pass or fail, the server despawns the fixture creatures, leaves the case's groups, logs
  out its players and drops pending harness queries. When a character name can be reused (one lane, or an
  explicit fixture `name`), it then deletes the case accounts with their characters and checks every 50 ms whether
  the accounts and character names are gone, deleting again whatever is still visible. The first check that
  finds none releases the lane; teardown does not wait for character writes still queued at that moment, so a
  character creation queued when the case failed can commit afterwards and restore its name, and the next case
  that creates that name can then fail at setup. With more than one
  lane, generated names are never reused, so those accounts and characters stay in the server's disposable schemas.
  The server writes the case result only after this teardown, so the teardown counts toward the case's time.
  A teardown failure fails that case (`Teardown failed: ...`), stops the server and fails the batch.
- Each result carries `run_id`, `batch_id` and `sequence`, so it cannot be confused with another case.
- Queue mode needs one asynchronous login database worker (the runner sets it) and `Cluster.Enabled=0` in the
  worldserver config; otherwise every queue server stops at startup. The runner also sets the character database
  workers and isolation; see [Character database](#character-database).

### Shared server state

Only the items above are reset. Cases on one server share the worldserver process: map state outside the
fixtures, loaded data and caches, configuration, script state and world database contents persist from one case
to the next, and on the simulated clock concurrent cases share them while they run. A result can therefore depend
on the cases that ran earlier on the same server, and queue order changes between runs as durations and job
counts change.

Each server's auth and characters schemas (`coa_test_<batch id>_auth|characters`) serve all of its cases and are
dropped when the server stops. The world audit also runs once, after the server stops: a persistent world write
by one case is visible to the later cases on that server and discards the slot's world copy at the end.

One worldserver and module configuration applies to every case, so scenarios that document different required
config values cannot all pass in one run; see [Full runs](#full-runs).

### Character database

Real-clock and single-mode worldservers keep the reference settings: one asynchronous character database worker
at the MySQL server's default transaction isolation. The simulated-clock worldserver sets
`CharacterDatabase.WorkerThreads` to `batch.py --character-db-workers` (1-32, default 16; `verify_all.py` passes
`--gameplay-db-workers` or the `gameplay_db_workers` setting) and `CharacterDatabase.TransactionIsolation` to
`READ-COMMITTED`. The worldserver applies that isolation to every connection of the pool, synchronous and
asynchronous, each time it connects. The login database keeps one worker. The harness reports its character
database workers and the isolation its connection reads back in `ready.json`, and the runner rejects a server
whose values differ, such as a build without this setting. `gameplay.json` records both values in `simulation`
(`character_db_workers`, `character_db_isolation`). Every harness worldserver keeps the login and world databases
at the server's default isolation. Module configs and `AC_*` environment variables cannot change these settings.

Character creation and login dominate simulated setup. With one worker, the creations of all lanes queue behind
each other. With several workers at `REPEATABLE-READ`, concurrent creations deadlock on gap locks: saving a new
character first deletes its not-yet-existing rows, which locks the gaps next to neighbouring GUIDs, and the core
retries each deadlocked transaction alone. `READ-COMMITTED` takes no gap locks for those deletes. On a 60-case
sample with 15 lanes, mean setup per case was 8.4 s with one worker, 3.5 s with 4, 2.6 s with 8 and 1.65 s with
16, all without deadlocks; 4 workers at `REPEATABLE-READ` took 5.5 s and deadlocked 71 times. 24 and 32 workers
cut mean setup further, to 1.45 s and 1.47 s against 1.65 s over three runs at 16, but startup plus case phase
stayed within run-to-run noise (40.4 s and 43.1 s against 39.2-42.4 s at 16). The default of 16 is about one worker
per lane, not a measured optimum. On the full catalog, 16 workers cut the case phase to 271 s, from 752 s with 4
workers at `REPEATABLE-READ` and 1067 s with one worker.

Several workers can commit one session's writes in a different order than they were queued, so a case that reads
back its own asynchronous character write can fail accelerated and pass at real pace; rerun it with
`--gameplay-db-workers 1` to tell that apart from clock timing (see
[Accelerated verdicts](#accelerated-verdicts-and-optional-diagnostics)). Teardown queues each account deletion
once and retries residual character cleanup until the account rows, character rows and character cache entries
are gone. It does not wait for every queued write; see [Per-case isolation](#per-case-isolation) and
[Fidelity limits](#fidelity-limits).

`READ-UNCOMMITTED` and `READ-COMMITTED` need row-based binary logging: with binary logging on and
`binlog_format = STATEMENT`, MySQL rejects every InnoDB write at those levels (error 1665). The worldserver checks
this when it connects and stops at startup instead, so the simulated-clock server needs `binlog_format` `ROW` (the
MySQL 8 default) or `MIXED`, or binary logging off; the real-clock reference is not affected.

### Isolated reruns and `batch_sensitive`

On the real clock, every failed or not-run catalog case is rerun once in single mode, with its own worldserver and
databases, under `isolated/<id>/`, except a case with an `hour`, which already ran in single mode. Reruns use the
worker slots, one at a time per slot. If the rerun passes, its bundle is used for combined verification and the case
counts as `passed_on_isolated_rerun`. Its id is listed in `batch_sensitive` when its queue-mode attempt failed, and
in `isolated_only` when that attempt did not fail itself (the case did not run, or only its server's cleanup
failed). Exploratory scenarios are not rerun. Reruns are skipped, with a batch failure, when no queue-mode
worldserver became ready or the worldserver binary changed during the batch.

A `batch_sensitive` scenario passed alone but failed after other scenarios shared its server. The stage can
still pass, but report these ids: they point to leaked state, an order dependency or a scenario that relies on
a fresh server. Report `isolated_only` ids as well: they passed only in isolation.

### World-cache slots

Worker `k` (only worker 0 on the simulated clock) uses the world cache at
`.cache/coa-gameplay-tests/world-cache/slots/slot-<k>`, separate from the single-run cache in
`.cache/coa-gameplay-tests/world-cache/`. Each slot has its own lease and retains its own
`coa_test_<cache-id>_world` copy, so the first run of a new slot copies the world database and every extra
gameplay job keeps another copy in MySQL. Reuse and invalidation follow the single-run rules in the
[gameplay README](../../apps/coa-gameplay-test/README.md#reusing-the-world-database). Changes that the cache
fingerprint cannot see, such as source SQL outside the fingerprinted directories, world views or stored
triggers, routines and events, are outside what the gameplay stage verifies.

A lease blocks every other user of that slot. Run one gameplay stage at a time, and never remove a lease until
its runner and worldserver are confirmed stopped.

### Server failures

When a worldserver is lost during a case, the server is stopped, its databases and cache are cleaned up and a
new server continues with the remaining queue:

- A crash or case timeout on the server's first case fails that case with the reason.
- An exit with an ordinary exit code (the harness stops itself only for teardown, isolation or queue protocol
  failures), or a crash or timeout after an earlier case on that server returned its result, cannot be blamed
  on the unfinished case: it fails the batch, and the unfinished case is queued once more. A second loss fails
  that case.

A real-clock worker takes one case at a time. On the simulated clock the runner counts as started the cases a
lane could have been running (the first `lanes` unfinished case files, as exclusivity allows):

- A crash or timeout with one started case on a server that has not returned a result yet fails that case with
  the reason, as on the real clock, and the batch does not fail.
- Otherwise the batch fails. Each started case is queued once more and runs alone, like an exclusive case; one
  that was already queued once fails.
- Cases written ahead that had not started are queued again without using their retry.

After three consecutive server failures without a completed case a worker stops, which fails the batch; the
other workers continue with the shared queue. Cases that no worker could run are `not_run`, which is a failure.
A batch in which no queue-mode worldserver became ready fails without isolated reruns. A cleanup failure marks
every case of that server `cleanup_failed` and fails the batch. The binary is hashed before each server starts;
a change during the batch stops new servers and fails the batch. Ctrl+C or SIGTERM (a console break on Windows)
stops all servers and cleans up.

## Harness prerequisites

Before running, the harness stage classifies each script from its source:

- Outside Windows, a script that reads `os.environ['VCToolsInstallDir']` and names no portable compiler (`CXX`,
  `clang`, `g++` or a quoted `c++`) is `unavailable` while that variable is unset (requires the MSVC toolchain).
  A script that also names a portable compiler runs. On Windows, while the variable is unset, a script that
  reads it by subscript without an `os.environ.get` lookup is `unavailable`, and any other script that mentions
  it runs only when `$CXX` or `cl.exe` is on `PATH`.
- A script that references a `Test-*.py` workspace tool is `unavailable` when a referenced tool is missing.
  A script that declares `--workspace-tools` looks in `workspace_tools` (default `<repo>/../tools`) and receives
  that directory with `--workspace-tools`; any other script is checked against `<repo>/../tools`.
- A script that reads a fixed path beside the repository (`ROOT.parent / '<path>'` outside an argument default)
  is `unavailable` when that path is missing.
- A script with a required argument the settings cannot supply is `unavailable`. The suppliable arguments are
  `--spell-dbc` (`<dbc>/Spell.dbc`), `--dbc-dir` (`<dbc>`), `--datamine-dir` (`datamine_directory`) and
  `--mysql-bin` (`mysql_server_bin`); optional
  ones among them are passed whenever available.

Every other script runs: exit code 0 passes, anything else fails and keeps the end of its output. Optional
arguments outside that list, such as `--client-addon-dir`, `--trainer-policy` or `--source-ref`, are not passed,
so the extra checks they enable are not part of the run. `--plan` shows each script's classification before
anything runs. An unavailable script makes the harness stage `unavailable` unless another script failed.

Some scripts are unavailable on every setup, and others depend on the machine; `--plan` lists the current set
with reasons:

- Without `mysql_server_bin`: `apps/coa-world/test_mysql.py` and `apps/test-framework/test_class_stat_progression.py`,
  `test_enchantment_migrations.py` and `test_starting_action_bars.py`, which start their own `mysqld`.
- Outside a Visual Studio developer environment: the MSVC-only scripts, most of them `apps/coa-tests` harnesses.
- Without the external workspace tools: the scripts that reference their `Test-*.py` files.
- Without `datamine_directory`: `apps/coa-tests/greater_imp`, which also requires MSVC.
- Without `<repo>/../client-reference/coa-datamine/raw/tables`: `apps/coa-tests/secondary_appearances`.

Report these scripts as unavailable, never as passed.

## Full runs

A run of every stage without focus filters cannot currently end `PASSED` on any setup. It ends `FAILED`, or
`INCOMPLETE` when the gameplay stage is unavailable and nothing else failed:

- One worldserver and module configuration applies to every gameplay case, including the reruns, and
  some scenarios require opposite values. `who-hides-bots` needs `Who.ShowBots=0` while `who-lists-bots` expects
  the shipped `1`; `destiny-weaver-quest-fallback` needs `DestinyWeaver.Enable=0` while `destiny-weaver-scaling`
  needs it at `1`. Others, such as `profession-xp-disabled`, `profession-xp-global`, `high-risk-death-chest`,
  `destructo-bot-manastorm` and `pvp-power-damage`, name their required values in their `contract`. At least one
  scenario of each opposing pair fails on every configuration.
- The always-unavailable harness scripts above keep the run from `PASSED` even when everything else passes.

Classify every failed or blocked stage, failed or `not_run` case and failed or unavailable harness script:

1. Documented prerequisite: a scenario whose `contract` names a config value that the run's configuration does
   not have, a stage or harness script that is unavailable for a reason this guide describes, or the
   [authorized SQL exception](#authorized-sql-outside-pending-updates). When the change concerns such a
   scenario, verify it in a focused run whose `--settings` names a configuration with the documented value.
2. Pre-existing: the same id fails or is unavailable on the PR base with the same settings and gameplay clock.
   Compare with a full run of the base commit, whose `report.json` and `gameplay/gameplay.json` stay usable
   while the base and the settings are unchanged, or rerun only those ids on a checkout of the base
   ([Separate worktrees](#separate-worktrees)).
3. Acceleration-specific: a gameplay case that fails on the simulated clock and passes a
   [real-clock reference run](#real-clock-reference-runs) of the same checkout and settings
   (`--gameplay-clock real --scenario <id>`). Report both outcomes; an affected accelerated failure must be
   repaired before accepting a normal issue batch. Do not use the slower pass to clear it.
4. New: everything else. Treat a new failure as a regression caused by the change until shown otherwise; it
   blocks a PR.

Report the actual `FAILED` or `INCOMPLETE` status with the ids in each class. A run whose failures are all
documented, pre-existing or acceleration-specific is not `PASSED`; say which classes remain.

### Authorized SQL outside pending updates

`verify_all.py` has no option that allows historical SQL. When the task explicitly authorizes an edit outside
`data/sql/updates/pending_db_*/`, the source stage fails in `tools/check_change_boundaries.py`. Confirm in
`source.log` that its `sql_outside_pending` list names only the authorized files and that every other source
command passed, then report that failure as the authorized exception with those file names. On the pull
request, a maintainer's `sql-change-authorized` label covers the exception in CI.

## Coverage boundaries

Gameplay scenarios run real game objects, handlers and character loading through socketless sessions. They do
not cover network authentication, client packet delivery, rendering, tooltips, animations or UI input.
Deployment and in-game acceptance remain separate scopes.

Authoring and discovery tools stay available and are not verification: `run.py validate <scenario>` checks a
definition while writing it, `catalog.py` and `workflow.py` find scenarios, and `verification.py` rechecks
recorded result bundles without starting a server.

The [Docker Compose gameplay service](../../apps/coa-gameplay-test/README.md#linux-docker) runs single scenarios
outside `verify_all.py`, for Docker-only installations. Use it only when the user asks for it, and report its
results as single-scenario evidence, not as a `verify_all.py` result.
