# CoA gameplay tests

Execute repeatable scenarios inside a real worldserver, using its loaded DBCs, SQL, scripts, maps and updates.
The runtime component is `src/server/coa/CoAGameplayTest.cpp`; it is disabled by default. Scenarios are verified
through the gameplay stage of [`tools/verify_all.py`](../../docs/coa/verification.md), which runs them with
`batch.py` in queue mode, by default up to 15 at once in one worldserver on a
[simulated clock](../../docs/coa/verification.md#accelerated-single-server-mode); this directory's runners are its
implementation.

## Find and verify a mechanic

The searchable catalog derives spell IDs, classes, assertions, metrics and contracts from the scenarios.
`checks.json` binds the existing numerical result checkers to their exact scenario definitions and mode arguments.
Use the [agent DBC viewer](../coa-dbc/README.md#agent-retrieval-coa-dbc-viewer) to inspect source data first.
The [mechanic map](../coa-mechanics/README.md) connects spells and quests to ranks/acquisition, expected behavior
and reviewed execution paths. `catalog.py --quest ID` and `workflow.py --quest ID` select quest investigations.

```sh
python apps/coa-gameplay-test/catalog.py --spell 1257670
python apps/coa-gameplay-test/catalog.py --query 'replenishment'
python apps/coa-gameplay-test/workflow.py --spell 1257670
python apps/coa-gameplay-test/catalog.py --check
```

`workflow.py` returns candidate scenarios and an investigation sequence in JSON. It does not infer that a
report is a defect or create a PR. Establish expectations independently, select a metric that observes the
behavior, reproduce it, then classify the result as a defect, already working, an incorrect test or unresolved.
Use the existing issue-to-PR workflow when that scope is requested.

The gameplay stage combines native execution with every registered numerical check for each exact catalog
scenario it runs. Checks requiring companion scenarios (currently the two Rockslide selection cases) add both
cases to the selection automatically. Its `gameplay/verification.json` covers every selected catalog case,
includes executable/scenario/checker identities, and decides the stage's outcome together with each case's
native result. Native failures also produce a failed combined outcome, with required checks marked `blocked`
when their native evidence is unavailable.

For example, the existing Primalist conversion script has two registered modes:

| Scenario | Required checker | Mode argument |
| --- | --- | --- |
| `primalist-everlasting-rage` | `check_primalist_native_conversions.py` | `everlasting` |
| `primalist-king-mountain` | `check_primalist_native_conversions.py` | `king` |

Select the scenario once; there is no separate checker command to remember:

```sh
python -B tools/verify_all.py --stages build,gameplay --scenario primalist-everlasting-rage
```

A scenario file that differs from its catalog definition is exploratory: pass its path to `--scenario`. It runs
natively only, is reported separately and never produces a combined pass, but it must pass for the stage to pass.
A selection of exploratory files only ends `INCOMPLETE` (an `unavailable` gameplay stage) even when they pass.
Native success alone cannot pass a failed, missing or timed-out required numerical check.

`run.py run` is the single-scenario runner behind the stage's isolated reruns and the Docker service. It runs a
catalog scenario and its companions in their own worldservers and writes `verification.json` in the first
case's result directory; `NATIVE STAGE COMPLETE` is intermediate progress and only `VERIFICATION PASSED` means
the combined checks passed. Its `--native-only` option is the exploratory equivalent.

For new spell or quest regressions, save the reusable definition under `scenarios/`. Express direct assertions
in that definition and add any extra numerical checker to `checks.json`, listing scenario IDs in its expected
argument order, followed by mode arguments in `args`. Shared checks can list multiple scenarios; the runner
selects their companions transitively. Registry validation runs before native execution and in CI, and rejects
missing files, duplicate bindings and any `check_*.py` script left unregistered. Scenarios with no extra checker
still receive combined verification of native completion, assertions and cleanup.

Recheck recorded result bundles without starting a server:

```sh
python apps/coa-gameplay-test/verification.py .cache/verify-all/STAMP/gameplay/cases/frostbolt
python apps/coa-gameplay-test/verification.py path/to/rockslide-first path/to/rockslide-highest
```

Rechecks require the exact current scenario definition, its recorded hash, matching native step/run identity,
passing native assertions and cleanup, all companion results, and matching companion executable hashes.
They do not establish that old results cover current source, database, config or client changes. The registry
ensures checkers run; it does not prove every expected mechanic has an adequate scenario or independent contract.

## Prevent recurring mistakes

Run the fast source checks for the working diff, including staged and untracked files, through the `source`
stage:

```sh
python -B tools/verify_all.py --stages source --base HEAD
python -B tools/verify_all.py --stages source --base origin/main
```

`source.log` holds the outcome of `tools/check_source.py`: the selected checks, failures and timings;
`report.json` lists the selected suites and failed commands. `--plan` shows only the command, not the selection.
Without `--base` the stage runs every fast suite but compares with `HEAD`, so committed changes are not
boundary-checked; pass the PR base before a PR (see the
[source comparison base](../../docs/coa/verification.md#source-comparison-base)). SQL boundaries and new
C++/Python comments in CoA-owned code are always checked; changed CoA sources select loader registration
checks; gameplay tooling/scenario changes select scenario validation, combined-verification tests, and
runner/cache ownership and cleanup tests. Reviewed execution-path changes also check mechanic-map references.
Documentation-only changes skip these test suites.
CI uses the same selection for pull requests and retains the repository publication checks. Main-branch and
manual runs perform a full audit; SQL-boundary exceptions are reviewed on the pull request. The existing compiled
client-compatibility harness runs in CI only for relevant changes or a full audit; locally the `harness` stage
runs it. The source stage never builds or starts a server.

CoA-owned code uses names, structure and tests to express intent. The comment check covers
`src/server/coa/`, `apps/coa-tests/`, `apps/coa-bugreport/`, `apps/coa-dbc/`, `apps/coa-gameplay-test/`,
`apps/coa-mechanics/`, `tools/` and `.github/scripts/`. It rejects explanatory comments and docstrings on added lines, while preserving legal
headers, recognized tool directives and native test-generator markers. Strings and runtime CLI help remain data.
Without `--base`, the source stage also checks unchanged C++ and Python files in those directories.
Upstream source, dependencies, SQL and configuration documentation remain outside this check.

The loader check requires each CoA `AddSC_*`, `AddAscension*Scripts` and `AddCoA*Scripts` definition to have
exactly one call from the flat CoA script loader, and each call to have exactly one definition. It ignores comments
and string literals. It does not prove SQL bindings, hook reachability, or gameplay behavior; those require data
inspection and behavioral tests. The checker intentionally reports an unsupported conditional loader for review.

For behavior, choose the existing scenario that observes the changed mechanic and select it with
`verify_all.py --scenario <id>`:

- **Duplicated calculations:** `bloodmage-dominion-of-blood-vampiric-fang` compares healing with the same cast's
  damage; doubled healing fails the ratio. `ascension-replenishment` checks exact amounts for different recipient
  pools. For a new coefficient change, vary AP/RAP/SP independently and check the final affected hit or tick.
- **Wrong ownership:** `primalist-sharpened-claws` includes a wrong-caster pet control;
  `wisdomball-dungeon-quests` checks the interacting player's quest state without changing the summoner's state.
- **Rank replacement:** `pyromancer-fix-4104-ascension-rank-supersede` and `runemaster-tattoo-rank-supersede`
  verify that a superseded rank cannot apply its aura, the current rank can, and the lower aura stays absent
  while the higher aura is active. A stat-stacking change also
  needs its effective stat/damage assertion; checking only the learned spell list is insufficient.
- **Cleanup:** `primalist-protectors-hand` verifies armor returns after removing all sources;
  `primalist-sharpened-claws` covers expiry and unlearning. Runner/cache tests separately cover database ownership,
  collisions, leases, failed audits and unstopped processes; infrastructure cleanup is part of combined verification.
- **Damage-based healing:** `reaper-siphon-anima` confirms a Reaper hit on a separate target and checks the
  resulting health gain against the five-percent Siphon Anima aura.
- **Chance-limited procs:** `reaper-beyond-death-reliquary` counts the ordinary Soul Bolts and the additional
  helper casts and damage hits across 90 trials. Its 8% chance still leaves about a 0.055% chance of no proc.

Keep expectations independent of implementation. Use distinguishable players/stats, positive and negative
controls, and bounded final values; a broad “damage increased” assertion can miss double scaling. The fast tests
inject doubled amounts, wrong-recipient values and retained auras into synthetic recorded results to prove those
errors cannot pass verification. These checks validate the verifier, not current worldserver behavior. Source
patterns cannot reliably establish these gameplay rules, and passing source checks is never a gameplay pass.

## Run

Python 3.11+, MySQL 8 client tools, a local MySQL server and a worldserver built with the runtime component
are required. `tools/verify_all.py` finds them through `conf/verify-all.json` or auto-detection and builds the
worldserver in its `build` stage; see its [setup](../../docs/coa/verification.md#setup). Docker installations
on Linux can use the [Compose test service](#linux-docker), which provides all of them.
Adding the new source requires CMake
reconfiguration before building; running an older binary will fail the readiness check.
The CoA server component requires Boost.PropertyTree headers. Component-based vcpkg installations need
`boost-property-tree` for the same triplet as the existing Boost libraries. CMake checks this dependency.

Validate a definition while writing it, then verify it:

```sh
python apps/coa-gameplay-test/run.py validate apps/coa-gameplay-test/scenarios/frostbolt.json
python -B tools/verify_all.py --stages build,gameplay --scenario frostbolt
```

`run.py validate` checks the definition without starting a server; it is not an execution result.

Every worldserver gets fresh `coa_test_<id>_auth` and `coa_test_<id>_characters` schemas: one pair per
queue-mode server, shared by its cases, and one per single-scenario run. Each case creates and deletes its
own accounts and characters. A world-cache slot creates a reusable `coa_test_<cache-id>_world` copy on its
first run, then reuses that world database.
The copies include world data, auth/character schemas, RBAC, realm definitions, active arena season and
migration metadata.
Existing accounts and characters are not copied. The MySQL user needs read access to the sources and permission
to create/import/drop the test schemas. Sources must be local. No authserver or game client is needed.
The copies omit MySQL triggers, routines and scheduled events.

If the normal server account cannot create schemas, set `database_client_config` in `conf/verify-all.json`
(the runners' `--database-client-config`). The existing MySQL `[client]` file must provide `host`, `port`,
`user` and `password`, with the same host/port as all source connections. Its credentials are used for
cloning, the isolated server and cleanup. For the local Repack, this file is
`C:/Ascension/CoA-Repack/mysql/admin-client.ini`. Credentials stay in temporary config files, never command
arguments or reports; no grants or existing accounts are changed.

The generated config binds the test worldserver to loopback on an unused port, uses a private log directory,
disables map worker threads and points all three database connections to isolated schemas. It keeps one
asynchronous login and character database worker at the MySQL server's default transaction isolation, except
on the simulated-clock worldserver, whose character database uses `batch.py --character-db-workers` workers
(default 16) at READ-COMMITTED; see [Character database](../../docs/coa/verification.md#character-database). These
database settings are harness controls too. Its `TempDir` is
the runner's private temporary directory, so the SQL updater's password file is neither shared between
concurrent test servers nor left in the system temporary directory. Source SQL updates
run normally against the copies. Source configuration and the installed server are not changed. Relative
`DataDir` is resolved against the binary's directory; use an absolute path when that differs from your setup.
Module `.conf` files beside the source config (in `modules/`) are copied into the directory the worldserver
reads module configs from, then removed at the end; the gameplay stage copies them once for all its servers.
Use `modules_config_dir` (`--modules-config-dir`) for a different source location.
On Windows that directory is `configs/modules/` relative to the working directory (the test directory), the
default. Elsewhere the worldserver reads `CONF_DIR/modules/`, fixed at build time, so `server_modules_dir`
(`--server-modules-dir`) is required; `verify_all.py` defaults it to `<CONF_DIR>/modules`. Use a directory
without module `.conf` files of its own, as in an isolated test installation. Existing files there are never
replaced, and additional `.conf` files are rejected so they cannot change the test settings. Copied file hashes
appear in the summary. Module configs cannot override database isolation or harness controls.

Source settings follow the server's precedence: an `AC_*` environment variable (for example `AC_DATA_DIR`)
replaces the value in the source config. The test worldserver inherits the runner's environment except
variables that would replace generated harness values, such as `AC_UPDATES_ENABLE_DATABASES` or
`AC_LOGIN_DATABASE_INFO`, so the generated config always controls isolation, logging and updates. A single-mode
run of a scenario with an `hour` sets `TZ` to a fixed offset that puts local time at the start of that hour, and
its `summary.json` records it as `timezone`.

In single mode the runtime logs out its test players and shuts down when the scenario ends. In queue mode it
tears each case down, deletes the case's accounts and waits for the next case until the runner sends a stop case
([queue-mode semantics](../../docs/coa/verification.md#gameplay-queue-mode)). The runner waits for process
exit before dropping the auth/character schemas, auditing the cached world and removing generated credentials.
Credentials are written only to mode-600 option files and a generated `worldserver.conf` in a private temporary
directory of the runner, never under the result directory; the directory is removed when the run ends.
Startup, scenario, shutdown and copy operations have timeouts. An interrupted run (Ctrl+C, or SIGTERM as sent by `docker stop`/`compose stop`)
performs the same cleanup. A hard termination or cleanup failure can leave schemas and a cache lease behind.
Inspect `summary.json` and the lease before removing any leftovers.

## Reusing the world database

Reuse is the default. Each case still gets fresh accounts/characters, so inventory, talents, quests and other
character state cannot carry over. The cache saves the full world import on later runs.
Single-scenario metadata lives under `.cache/coa-gameplay-tests/world-cache/`; `--world-cache-dir` selects a
different directory. The gameplay stage gives each worker its own slot under
`.cache/coa-gameplay-tests/world-cache/slots/` (`batch.py --world-cache-root`), used by that worker's servers
and isolated reruns.
Each directory contains ownership metadata and an exclusive lease, not credentials or SQL dumps.

`verify_all.py` passes either option to its gameplay stage (and the runners `run.py run` and `batch.py` accept
them directly):

- `--refresh-world`: replace the owned world copy before running, then retain it if the scenario leaves it clean.
- `--fresh-databases`: bypass the cache, copy all three schemas and drop them after the run, for a completely
  fresh database baseline. It also works with older harness binaries.

The runner checks source table contents and definitions, repository SQL files under `data/sql/updates`,
`data/sql/custom` and `modules`, the source/main module configs and inherited `AC_*` settings. Changes refresh
the cache automatically. Environment values enter only the fingerprint, never the cache metadata as plain text.
Source SQL stored elsewhere needs an explicit `--refresh-world`. C++ edits and a new binary alone do not force
a full copy. Cache ownership also includes the MySQL server identity, host, port and source world schema.

Startup migrations run before the native startup barrier. The runner records the world state at that barrier,
then releases character loading and scenario actions. After shutdown it compares the world again. Persistent
world writes, including console edits, discard that copy. A failed gameplay assertion can still leave a clean,
reusable world. Auth/character databases are always discarded after the owned server stops.

Content checks use MySQL `CHECKSUM TABLE ... EXTENDED` and table definitions. They still scan the data and can
briefly block writes to a table while it is read; reuse skips copying/importing rather than all database work.
Checksums can collide, so reuse is a regression-testing optimization, not a proof of byte-for-byte equality.
See the [MySQL checksum documentation](https://dev.mysql.com/doc/refman/8.4/en/checksum-table.html).
World views, stored triggers/routines/events or unavailable checksums require `--fresh-databases`.
Avoid changing source data during a run.

Only one run can lease a given cache. A second run fails before using it; `--fresh-databases` allows an independent
concurrent run. A hard interruption or an unkillable server keeps the lease blocked. Check the lease's runner PID
and result directory and verify that its worldserver has exited before recovering it; never delete a lease to
override a running test. Refresh does not bypass a lease or an ownership mismatch.

`summary.json` records `world_cache.mode` (`created`, `reused`, `refreshed` or `fresh`), the retained world schema,
invalidation reason, and preparation/server/total seconds. A retained world with `retained: true` is intentional.
Generated credential and module configuration files are removed on every normal cleanup.

The gameplay stage writes each catalog case's queue-mode or accelerated attempt under `gameplay/cases/<id>/` of
its output. Explicit `--gameplay-real-pace-rerun` diagnostics are under `gameplay/real-pace/<id>/`; an isolated
rerun is under `gameplay/isolated/<id>/`; `cases.<id>.directory` in `gameplay/gameplay.json` names the bundle
that decided the verdict. Each exploratory scenario file gets a bundle under `gameplay/exploratory/<key>/`
and each server's logs
are under `gameplay/servers/`. Normal verification runs accelerated only; repair fast failures before accepting
a batch. A single-scenario run writes its bundle to `.cache/coa-gameplay-tests/<run-id>/`
by default. The [verification guide](../../docs/coa/verification.md#results-and-exit-codes) lists the batch
files.

- `scenario.json`: exact scenario used.
- `worldserver.log`: process output, including startup and script errors (in the server directory for a batch).
- `result.json`: server version, actual values and step outcomes.
  Failed cases include `failure_actors` with native positions, combat targets and controlled-unit movement.
  Fixture teardown removes descendants of cloned creatures before their private phase is reused.
- `summary.json`: native-stage result, binary/scenario SHA-256 and any cleanup failure.
- `verification.json`: combined native and registered numerical verification for catalog scenarios (one file
  for the whole selection in a batch).

A passing outcome requires every expected assertion and step to complete, matching run identity, a clean server
exit, successful cleanup/cache audit and every registered numerical check. A submitted cast alone is never a pass.
Numeric fields in the server's property-tree JSON are strings; the Python runner converts and rechecks assertion values.

### Linux (Docker)

This service runs the single-scenario runner inside the worldserver image, for Docker installations without
the local build and MySQL client tools that `verify_all.py` uses. It is the one execution route outside
`verify_all.py`: agents use it only when the user asks for it. Its results are not part of a `verify_all.py`
report; report them as single-scenario evidence.

`docker/compose.yml` adds the `ac-gameplay-test` service to the root Compose stack. It uses the locally built
worldserver image plus Python and shares the `ac-database` network namespace, so MySQL is reachable on
`127.0.0.1` and the isolation checks are unchanged. The repository is mounted read-only (runner, scenarios and
SQL updates), the live `DOCKER_VOL_ETC` configs are read-only sources, and `DOCKER_AC_ENV_FILE` applies the same
`AC_*` settings as the live worldserver. The service selects the same `acore_auth`, `acore_characters` and
`acore_world` source schemas as the root Compose stack, using `127.0.0.1:3306` inside the shared network namespace.
Its database environment variables override any stale connections in `worldserver.conf` or the environment file.
If another Compose override changes the live schema names, mirror those names in this service's
`AC_*_DATABASE_INFO` variables while retaining the loopback endpoint. Build the worldserver image from the same
checkout first, with CoA and the cache startup barrier; rebuild the test image after it. A mounted
source checkout does not update the compiled server. Prefer rebuilding only the required test targets.

```bash
mkdir -p .cache/coa-gameplay-tests
docker compose -f docker-compose.yml -f apps/coa-gameplay-test/docker/compose.yml --profile tests \
  build ac-gameplay-test
docker compose -f docker-compose.yml -f apps/coa-gameplay-test/docker/compose.yml --profile tests \
  run --rm --no-deps ac-gameplay-test run apps/coa-gameplay-test/scenarios/frostbolt.json
```

Run these commands from the checkout that owns the running stack (matching project name and `.env`), or pass
`--project-name`/`--env-file` explicitly. The example assumes the database is already healthy and configs and game
data have been initialized. `--no-deps` prevents starting or changing dependencies. For `validate <scenario>`,
also use `--no-deps` so Compose does not start MySQL; validation itself does not connect to it. The entrypoint fixes
`--worldserver`, `--config`, `--modules-config-dir`, `--server-modules-dir`, `--mysql`, `--mysqldump`,
`--database-client-config`, `--world-cache-dir` and `--output`; passing any of them after the scenario has no effect.
The results mount also stores persistent cache metadata at `/results/world-cache`, corresponding to
`.cache/coa-gameplay-tests/world-cache/` on the host. The default reuse, `--refresh-world` and `--fresh-databases`
options have the same behavior as direct invocation. A clean retained world schema is intentional; only fresh
mode drops all three schemas after each run. Cache lease PIDs and result paths refer to the container; verify the
owning container has stopped before recovering a lease.

The service connects as MySQL `root` with `DOCKER_DB_ROOT_PASSWORD` (it must not contain `"`, `;`, or a carriage
return/line feed; the runner rejects such characters before connecting). Credentials are written only to
mode-600 files in a private temporary directory inside the disposable container, never to the result
directory. The runner removes its generated files during cleanup; the entrypoint's admin file disappears when
the disposable container is removed (`--rm`). SIGTERM from `docker stop`/`compose stop` triggers cleanup,
including the world audit; allow enough time for database checks (individual checksums can take five minutes).
The service allows 15 minutes; for a manual stop use `docker stop -t 900 <container>`. A hard termination or
cleanup failure may leave schemas or a lease behind; inspect `summary.json` and the lease. Results appear in
`.cache/coa-gameplay-tests/<UTC timestamp with nanoseconds>/`. The service does not stop the running worldserver.

With matching server sources, game data, source databases and effective config, Docker invokes the same Python
runner and native runtime, including scenario validation, actions, assertions, SQL updates and cleanup. The
skill's experiment design applies, but there is no `report.json` or `gameplay/` tree. Inspect the run directory
instead: `summary.json` for the native result, binary identity, cleanup and `world_cache`; `result.json` for the
step outcomes and actual values; `verification.json` (catalog scenarios only) for combined verification; and
`worldserver.log` for startup and script errors. Only a final `VERIFICATION PASSED` line with a passed
`verification.json` is a pass; a `--native-only` run proves native execution only. This does not validate
client rendering or network login, and a static review alone cannot establish runtime parity between Windows
and Linux binaries.

## Scenario format

A creature fixture accepts `spell_hit_bonus` (0–100 percentage points) for its native spell hit modifier.
An omitted bonus uses the creature's normal stats. Require the observed hit as well as the configured modifier.
Optional `stationary: true` disables native movement for that fixture using `UNIT_FLAG_DISABLE_MOVE` and stops
its current motion. Other creatures retain their original movement. Use it for a fixed damage target when
wandering or fleeing would invalidate ordinary cast range or facing; it does not change spell hit or proc chance.

Start from [scenarios/frostbolt.json](scenarios/frostbolt.json). Schema version 1 accepts up to eight players,
eight creatures and 10,000 sequential steps. Optional `timeout_ms` bounds setup plus execution (default 90s,
maximum 10 minutes); execution counts in game time, which the simulated clock advances past waits. Optional
`contract` records the independently established expected behavior. Optional `hour` (0-23) starts the case in that
realm-local hour, for mechanics that read the time of day: the simulated clock, which otherwise starts at 10:00,
jumps ahead to it, and the real clock runs the case in single mode with a fixed `TZ` offset
([realm-local time](../../docs/coa/verification.md#realm-local-time)). Every result records its start as
`realm_local_start`. Optional `creature_scaling: true` enables CoA creature scaling with its built-in multipliers
for that case, whatever the module config says, and restores the configured state when the case ends; the batch
runs such a case exclusively because the setting is process-global.
The [talent and item scenario](scenarios/talent-and-items.json) exercises talent learning, passive removal,
equipping a shirt and consuming a healing potion. It does not measure the talent's damage coefficient.
The [Shadowblast scenario](scenarios/shadowblast-shadow-rage.json) reproduces a Shadow Rage pet-targeting crash
and checks the buff's recipient, with ordinary Frostbolt casts as a control.
The [Shadow Effigy scenario](scenarios/shadow-effigy.json) checks combat casts, one active effigy per owner,
nearby-enemy debuffs, replacement by another effigy and timed despawn.
The [Dusk Blade scenario](scenarios/dusk-blade.json) checks dual-wield damage, Rage spending and healing
the wounded caster across repeated melee casts.
The [Who scenarios](scenarios/who-lists-bots.json) check both sides of `Who.ShowBots`: bot sessions are listed
like players with the shipped `Who.ShowBots=1`, and the [hidden case](scenarios/who-hides-bots.json) requires
`Who.ShowBots=0` in the source config, where the same roster leaves only the two real players in the response
and a name search for a bot returns nothing.
The [resource talents scenario](scenarios/resource-talents.json) checks the live-tree 1% resource bonuses.
Arm of Thorim rolls 133–144 base damage at the fixture level, so two independent rolls need ratio ranges
of 1.10–1.31 with its 20% bonus and 0.91–1.09 without it (including integer rounding). Charged Conduit
preserves Static and must leave the talent without a depletion bonus.

Players require `id`, numeric `race` and `class`; `level` defaults to 80. Optional `bot` logs the actor in on a
session flagged as a bot, the way playerbots flags the sessions it creates, so a scenario can check what the
server does differently for them. Optional `spell_hit_rating`,
`spell_crit_rating`, `melee_crit_rating`, `ranged_crit_rating`, `ranged_hit_rating`, `melee_hit_rating` and
`expertise_rating` add fixture ratings through normal calculations, useful for preventing misses, dodges and
parries, or forcing critical hits, in deterministic tests.
Optional `allow_regeneration: false` suppresses only that fixture player's ordinary health/power regeneration
through the native regeneration hook. Spell costs, healing, energize effects and combat remain enabled.
It defaults to true and has no effect on other players or on a disabled harness.
Optional `expansion` (0..2, default 2) is the fixture session's expansion, as a realm with a lower `Expansion`
setting caps a real client's; it gates maps and profession ranks.
Optional `ascension_client: true` marks the socketless session as having negotiated Ascension compatibility,
including its spell modifier packet layout. It defaults to false. This tests server packet construction;
it does not perform socket authentication or verify delivery to a rendered client.
Characters are created and loaded through the existing character creation, enumeration and login
handlers with ordinary player security. A player may set `account_of` to an earlier player id to share that
fixture's disposable account; otherwise each player gets its own account. This supports account-wide state
checks through separate socketless character sessions and does not test simultaneous client authentication.
Optional `location` supplies `map`, `x`, `y`, `z`, `o` for a fixture
teleport. `location.ignore_access` optionally bypasses entry requirements for a fixture (for example a solo
raid test), without enabling GM mode during combat. Actors share their lane's phase (`1 << 30` with one lane) to
isolate ordinary spawns.

`wait` and `within_ms` use game time on both clocks. On the real clock it follows the wall clock at world-tick
resolution; on the [simulated clock](../../docs/coa/verification.md#accelerated-single-server-mode) it advances
in world steps of up to 25 ms, so keep timing assertions robust to one step.
Without `name`, players are `Harness<a..h>` with one lane and generated 10-letter names with several;
`Harness<a..h>` in `console` and `command` text is rewritten to match, so refer to players by actor id elsewhere.
A scenario that depends on process-global state, such as the Who list, belongs in `clock_policy.json`
([exclusive cases](../../docs/coa/verification.md#exclusive-cases)). A `set_phase` mask that includes the normal
world phase (mask 1) automatically runs exclusively, including in an exploratory scenario. Phases do not
separate creature text with
area, zone or map range, which `system_messages` counts.

The native fixture-cleanup companion cases also reserve the same phase to observe a deterministic case
boundary. They use the accelerated clock and normal queue without slower or isolated retries.

Creatures require `id`, player `owner` and template `entry`. Optional `distance` offsets X from their owner
(default 3 yards); `faction`, `level`, `health` default to 14, 80, 100000. They retain template data and AI,
with health regeneration disabled and `reaction` defaulting to passive (0); defensive (1) and aggressive (2)
fixtures exercise native target selection and movement. `victim` with a `target` measures whether that unit is
the actor's current attack victim. The native player-damage share a kill needs for loot and
reward is taken from the declared health, so a player's kill leaves a lootable or skinnable corpse. Pick a
template whose scripts suit the experiment.
Setup clears combat initiated by spawn-time AI before starting the scenario: a fixture whose AI engaged a player
while spawning evades at once. No step runs while any fixture is evading, so a spell or attack is never aimed at
a fixture that is resetting; the step's time keeps running meanwhile. Combat otherwise follows normal rules.
Creature AI can change initial fixture levels and maximum health. Let them settle before taking baselines;
assert stable maximums and final levels when testing damage coefficients.

| Action | Fields and behavior |
| --- | --- |
| `console` | `command`: execute one console command on the test server; capture its output. |
| `command` | `actor`, `command` beginning with `.`: execute with the player's normal permissions. |
| `whisper` | Player `actor`, `to`, `text`, optional `language` (Common by default): the client's whisper packet, sent as typed. |
| `learn`, `unlearn` | `actor`, `spell`: configure learned spells/passives through player APIs. `unlearn` accepts `all_specs: true` to remove the fixture grant from every specialization before testing a lower weapon rank. |
| `money` | `actor`, `copper`: fixture purse, so a priced trainer row can be bought on a character that starts with none. |
| `set_aura` | `actor`, `spell`, `stacks`: fixture aura state, within its stack limit; zero removes it. Optional `pet: true` selects the actor's current pet. |
| `cancel_aura` | Player `actor`, `spell`: native `CMSG_CANCEL_AURA` handler; assert the resulting aura state. |
| `cancel_mount` | Player `actor`: native `CMSG_CANCEL_MOUNT_AURA` handler, the dismount a client sends with a mounted cast. |
| `talent` | `actor`, `talent`, zero-based `rank`: learn with normal point/prerequisite checks; optional `command` skips the point and tier checks like the GM command. |
| `reset_talents` | `actor`: reset active talents through normal removal, without a trainer fee. |
| `specialization` | Player `actor`, `ChrSpecs.dbc` `id`: the client's specialization switch. Uploads the class tree plus the specialization's identity and signature entries as native `0x0727`, as `SwitchActiveChrSpec` and `ApplyPendingBuild` do, then waits up to 2 s for the server to activate it. With `refused: true` it instead waits for the upload's `0x072C` result and requires the specialization to stay inactive. |
| `advancement_rank` | Player `actor`, CharacterAdvancement `entry`, `rank` (0 removes): uploads the known entries with that rank as native `0x0727`, then waits up to 2 s for the server to apply it. With `refused: true` it instead waits for the upload's `0x072C` result and requires the rank to stay unapplied. |
| `client_packet` | Player `actor`, `opcode`, optional `fields` (a list of one-key objects: `u8`, `u32`, `u64`, `string` as a C string, `buyback_guid` slot, `actor_guid` player or creature id as a raw GUID, `packed_actor_guid` player or creature id as a packed GUID, `pet_guid` player id as the current pet raw GUID, `duel_arbiter` player id as the pending duel flag raw GUID, `stabled_pet` stable slot 0-3 as its pet number), `consumed` (default true) and `early` (default true): sends the request through the early packet hook as the client would, and a request that hook passes on reaches its logged-in core opcode handler, as the session would deliver it; `early: false` sends it through the packet hook the session update runs instead, as for `CMSG_SET_ACTIVE_MOVER` after the client enters the world. |
| `apply_appearances` | Player `actor`, `selection` mapping category ids to appearance ids: sends the complete array as native `CMSG_APPLY_APPEARANCES` (`0x0697`); unlisted categories are 0. The next step sees the result. |
| `cast` | `actor`, `spell`, optional `target` (self by default), `target_item` (an owned item entry) or `target_gameobject` (the nearest gameobject of that entry within 20 yards): normal session cast handler. |
| `attack` | `actor`, `target`: native melee attack request; optional `pet: true` sends the pet's attack command. Verify combat or damage with assertions. |
| `stop_attack` | Player `actor`: native melee stop request. |
| `pvp` | Player `actor`, boolean `enabled`: native PvP toggle request. Disabling retains the ordinary flag-removal timer. |
| `set_moving` | Player `actor`, boolean `enabled`: fixture the native forward movement flag for cast restriction tests. |
| `group` | `actor`, `target`, optional `loot_method` (0-4): fixture party; creates the actor's group if needed, adds an ungrouped player and sets the loot method. |
| `lfg_dungeon` | `actor`, LFGDungeons.dbc `dungeon`: fixture Dungeon Finder group; converts the actor's ordinary group to an LFG group assigned to that dungeon, as a completed proposal does. |
| `lfg_teleport` | Player `actor`, optional boolean `out` (default false): native `CMSG_LFG_TELEPORT` request into or out of the group's dungeon. |
| `lfg_join` | Player `actor`, LFGDungeons.dbc `dungeons` list, `roles` mask (1 leader, 2 tank, 4 healer, 8 damage): native `CMSG_LFG_JOIN` queue request, as the Dungeon Finder button sends it. A group leader starts the role check. |
| `lfg_set_roles` | Player `actor` in a group, `roles` mask: native `CMSG_LFG_SET_ROLES` answer to the group role check. |
| `lfg_accept` | Player `actor`: native `CMSG_LFG_PROPOSAL_RESULT` acceptance of the last Dungeon Finder proposal the actor received. |
| `lfg_final_credit` | Player `actor` in a Dungeon Finder dungeon: credits the final encounter of the group's assigned dungeon, as `encounter_credit` does for that boss, when the proposal chose the dungeon. |
| `encounter_credit` | Player `actor` in a dungeon, creature `entry`: credits that dungeon boss kill to the actor's map through the native encounter update, as a boss death does, including the Dungeon Finder completion it triggers. |
| `leave_group` | Player `actor`: native `CMSG_GROUP_DISBAND` leave request; fails if the player stays grouped. |
| `die` | Player `actor`: fixture death through self damage equal to current health; the body stays unreleased. |
| `release_spirit` | Player `actor`: native `CMSG_REPOP_REQUEST` for an unreleased body; fails if the player is neither a ghost nor alive afterwards. |
| `cast_charm` | Same fields: native pet-cast handler, with the charmed unit as the default target. `pet: true` casts from the player's pet instead. |
| `gossip_hello` | `actor`, optional `target`: native gossip handler; defaults to the actor's summoned companion. |
| `banker_activate` | `actor`, optional `target`, or optional `owner` + `entry`: native banker click (`CMSG_BANKER_ACTIVATE`); defaults to the actor's summoned companion, and `owner` aims it at a companion another actor summoned, walking up to it first. |
| `personal_bank_open` | `actor`, bank object `entry`: native Personal Bank open (`CMSG_GUILD_BANKER_ACTIVATE`) on the nearest vault of that entry within 20 yards. |
| `personal_bank_swap` | `actor`, vault `entry`, `direction` `deposit` or `withdraw`, optional bank `slot` (default 0) and split `count` (0 moves the stack); `deposit` needs `item`, the first carried item of that entry. Withdrawals optionally take backpack `inventory_slot` (23-38), otherwise use automatic storage. Sends native `CMSG_GUILD_BANK_SWAP_ITEMS` into or out of the open Personal Bank. |
| `binder_activate` | `actor`, innkeeper `target`: native "make this inn your home" confirmation (`CMSG_BINDER_ACTIVATE`), walking up to the innkeeper first. |
| `destroy_item` | `actor`, `item`: native `CMSG_DESTROYITEM` of the first carried item of that entry, as the player deleting it. |
| `area_trigger` | `actor`, `id`: native area-trigger packet, as the client sends on walking into one; inn triggers are what set the rested flag. |
| `gossip_select` | `actor`, zero-based `option`: select from the current menu through the session handler. |
| `who` | `actor`, optional name-filter `target`, `class_mask`, `race_mask`: submit a native Who query. |
| `add_item` | `actor`, `item`, optional `count` (default 1): grant fixture inventory. |
| `fill_bags` | `actor`, optional `slots` (default 0): fill the bags with distinct non-stacking armor until that many free slots remain, so a scenario can prove what a full inventory does. Fails if the bags cannot be filled. |
| `equip` | `actor`, `item`, `slot` (0..18 equipment, 19..22 bag slots): equip an owned item through the session handler. |
| `use_item` | `actor`, `item`, `spell`, optional `target`, `target_item` (an owned item entry, sent as the item target instead of a unit) and `destination`: normal item-use handler. |
| `use_gameobject` | `actor`, `entry`: native use request for the actor's single nearby owned gameobject. |
| `summon_gameobject` | Player `actor`, `entry`, optional `distance` (yards in front, default 2) and `duration_s` (default 300): summon a gameobject the actor owns; fails if the actor already owns one of that entry. |
| `loot_gameobject` | Player `actor`, `entry`: open the loot of the actor's single owned chest as a successful open-lock cast does, so chest loot is generated for that player. Lock, key and skill checks are not exercised. |
| `mapless_loot_hook` | Player `actor`, `store` (`mail`/`gameobject`): test registered loot hooks without a map. |
| `set_skill` | `actor`, `skill`, `value`, `maximum`: fixture a native profession skill. |
| `gather_skill` | `actor`, gathering `skill`, `required`: native gathering XP and skill-up attempt. |
| `set_xp_enabled` | `actor`, boolean `enabled`: fixture the native XP-lock flag. |
| `set_level` | `actor`, `value` (1..80): fixture level change through native `GiveLevel`, including level-change hooks. |
| `set_health`, `set_power` | `actor`, `value` within native maximums; `set_power` accepts `power` (default 0). Optional `pet: true` selects the player's current pet. |
| `reset_cooldown` | Player `actor`, `spell`: reset that native spell cooldown between independent cases. |
| `restore_charges` | Player `actor`, `spell`: restore the native charge pool between independent cases. Separate from ordinary cooldowns. |
| `wait` | `ms`: let the world continue updating for that much game time. |
| `snapshot` | `actor`, `metric`, `save_as`: remember a numeric observation. |
| `assert` | `actor`, `metric`, `equals` and/or `min`/`max`: check an observation. |

`set_health` also accepts an explicit `maximum` for a player or their pet, using native `SetMaxHealth`.
This fixture supports exact health-percentage boundaries without granting GM permissions.

`gather_skill` calls `UpdateGatherSkill`; it does not harvest a node or prove loot delivery.

`xp` and `next_level_xp` read the player's XP fields; `skill_value` and `skill_maximum` require `skill` and read
the pure skill value and maximum. `spell_active` requires `spell` and reports whether a known rank is the active one.
`client_knows_spell` requires `spell` and is 1 when the spell packets sent to the player (initial list, learned,
superseded, removed and unlearned) leave it in the client's spellbook. `client_spellbook_copies` requires `spell`
and counts how many rows the client's spellbook holds for it: the client appends a row per announcement and only
its highest-rank view hides a spell that has ranks, so an unranked spell announced twice (a learned-spell packet
beside the superseded one that delivers it) is listed twice on screen.
XP-delta assertions must also keep the level stable, or crossing a level would wrap the XP bar.

Every step accepts a descriptive `label`. Assertions optionally accept `within_ms`: poll until the expected
state appears, failing at the deadline. This means "eventually", not "remains true throughout the window".
Equipment changes obey combat restrictions. Prepare gear before starting combat, including combat caused
by other nearby fixture actors. Rejected equipment actions include native inventory error codes in the result.

`spell_charges` requires a player's `spell` and reads its currently available native charges. Charge tests
must assert consumption and recovery after normal casts; restoring fixture charges does not prove recovery.
For absence checks, wait through the relevant cast/proc window first, then assert. `relative_to` subtracts
a previously named snapshot of the same metric; it is available on snapshots and assertions.
`ratio_to` then divides by a nonzero snapshot, including a different numeric metric such as healing/damage.
`cast` accepts an optional `destination` with `x`, `y`, `z` to send an explicit ground target.
`target_pet: true` in place of `target` sends a player's cast at their current pet.

Metrics: `health`, `max_health`, `creature_type`, `power`, `max_power`, `alive`, `map_id`, `combat`, `casting`,
`level`, `quest_objective_count` (needs `quest`, optional `index`), `knows_spell`, `has_talent`, `talent_points`,
`cooldown_ms`, `item_count`, `carried_item_count`, `bank_bag_slots`, `aura`, `aura_stacks`, `aura_charges`,
`aura_duration_ms`, `aura_amount`, `pet_entry`, `pet_aura_stacks`, `owned_creature_count`, `owned_creature_spacing`,
`charm_entry`, `charm_aura_stacks`, `controls_self`, `private_instance`, `dynamic_object`,
`dynamic_object_duration_ms`, `distance`, `spell_proc_count`, `spell_proc_chance`, `aura_proc_rate`,
`spell_cast_count`, `temporary_spell_replacement`,
`bank_shows`, `system_messages`, `cast_failure`, `pet_is_banker`, `pet_display`, `pet_scale`,
`pet_knows_spell`, `pet_distance`. `pet_health` and `pet_max_health` read native health and maximum health.
`equipped_item` takes `slot` (0..18) and reads that equipment slot's item entry, or zero when empty.
`free_inventory_slots` is how many bag slots the player could still fill, so `fill_bags` plus
`free_inventory_slots` `equals: 0` is how a scenario states "the bags are full". `mail_count` is the
number of mails the player holds and `mail_item_count` the items inside them, which is how a reward
that the bags could not take proves it was posted rather than lost; `mail_has_item` takes `item` and
returns whether any mail carries it, and `mail_pool_item_count` takes `cache` (optional `table`) and
counts only the mail items that are in that cache's own pool. `notifications` counts the
centre-screen notices a session has been sent and `notification_contains` takes `text` and returns
whether one carried it, which is how a test proves a player was told something in the middle of the
screen and not only in chat. The cache metrics are `carried_pool_item_count` (needs `cache`,
optional `table`: `prestigious`, `callboard`, or `loot` for the cache's item loot and its references, and
optional `min_required_level`/`max_required_level` that keep only carried items in that range; optional
`dominant_stat` keeps items whose strongest of Agility 3, Strength 4, Intellect 5 and Spirit 6 is that stat,
and `off_stat` keeps items that carry one of those four but whose strongest is not that stat), `pool_variant_count`, `pool_retired_item_count`, `pool_row_count`,
`pool_item_present` (needs `item`; `table` `fire_lord` with `cache` 2400040 reads Cache of the Fire Lord's
pool across every raid difficulty), and `cache_token_count`, `cache_token_stage`, `cache_token_present`
(need `cache`, the last also `item`), which read the token table the realm loads and answer how many
tier tokens a cache may pay, the highest tier among them, and whether one named token is among them.
Boolean metrics use 0/1. Spell/aura metrics require `spell`; `item_count` requires `item`.
`spell_family_flags` reads one word of the effective server spell's family flags; `index` is 0..2 (default 0).
`stunned` reads the unit's native stun state, including changes caused by aura removal.
`carried_item_count` sums the stack counts of equipped items (bags included), the backpack and the bags' contents.
`aura_positive` reads the applied aura's beneficial flag; check `aura` separately to distinguish absence from a debuff.
`gossip_options` counts the player's current server-side gossip options; it does not verify client rendering.
`gossip_option_text` needs `index` (zero-based) and `text` and returns whether that option carries exactly that
text, which is how a scenario holds the server to a client window that finds its buttons by their wording.
`trainer_list_packets` counts the trainer windows the session has been sent, `trainer_window_rows` is the row
count of the last one, and `trainer_window_state` requires `spell` and returns the state byte that window gave
the spell's row (`0` available, `1` unavailable, `2` known), or `-1` when the window does not hold that row.
They read what a client draws and gates **Train** on, so a window that stopped selling a spell is distinct
from one that still offers it.
`vendor_list_packets` counts the vendor lists the session has been sent, `vendor_items` is the row
count of the last one, `vendor_price` requires `item` and returns the price that list offered it at
(`-1` when the shelves do not hold that item), and `vendor_price_sum` is what the whole list costs -
a fingerprint of a vendor's stock, so one vendor can be held to another's items and prices.
`vendor_extended_cost` requires `item` and returns the ItemExtendedCost id that list sold it for (`0` for a
plain money price, `-1` when the shelves do not hold that item): the honor, arena point, token and rating
price a client reads from its own ItemExtendedCost.dbc.
`who_count` counts players in the actor's last native Who response; `who_class` requires a player `target`
and returns that player's class ID, or zero if absent. These inspect packets from socketless test sessions,
not client packet delivery. Masks use native Who bits (`1 << classID`, `1 << raceID`), with class 32 in bit zero;
omitted masks mean all. The custom-class scenario expects ordinary player RBAC, including faction separation.
`player_class` reads the player's current class byte and `cached_class` the class the character cache holds,
which is what name queries tell other clients. `at_login_flag` requires an `AtLoginFlags` value as `id` and
reports whether the player carries it (for example `8` customize, `64` faction change, `128` race change).
`health_pct` observes current health as a percentage of maximum health.
`creature_type` reads the native type used by creature-type targeting and effects.
`mount_display_id` reads the unit's actual mount display; zero means the unit is dismounted.
`cast_speed_multiplier` observes the native cast-time multiplier; smaller values mean faster casts.
`spell_crit_chance` observes the player's Shadow spell critical chance, in percentage points.
`spell_damage_done` and `melee_damage_done` require `target` and query native outgoing damage calculations
with a fixed base of 1000. The spell metric also requires `spell` and accepts `effect` (default 0); the melee metric uses a main-hand white hit.
`spell_damage_taken` and `melee_damage_taken` query the corresponding incoming bonus calculations for any
unit; `target` identifies the attacker, and `melee_damage_taken` optionally accepts a weapon-strike `spell`.
These queries do not execute attacks or include hit rolls, critical hits, armor/resistance mitigation, or proc
effects.
`spell_power_cost` requires `spell` and queries its current native resource cost; it does not submit a cast.
`spell_crit_chance` optionally accepts `school` (0..6, default Shadow). `melee_crit_chance`, `dodge_chance` and
`parry_chance` read the player's percentage fields; `expertise` reads main-hand expertise; `combat_rating` requires
`rating` (0..24, native `CombatRating`) and reads the rating value. `stat` requires `stat` (0..4), `resistance`
requires `school` (1..6); `armor`, `attack_power`, `ranged_attack_power`, the hasted `attack_time_ms` (optional
`hand`, 0..2) and `run_speed_rate` read the unit's current totals. `pet_attack_time_ms` uses the same hand
selection for a player's current pet and requires that pet to exist. `aura_amplitude_ms` reads an aura effect's
periodic interval.
`block_chance` reads the player's percentage field; `block_value` reads native shield block value;
`critical_block_chance` reads the total modifier used by the native critical block roll.
`moving` reads the unit's native movement state. `water_walk` reports whether the unit has a water-walking aura.
`in_water` reads the unit's water state; `terrain_in_water` checks the map's liquid data at its current position.
`ground_height` reads the map's top terrain/collision height at the current X/Y.
`owned_creature_display` requires `entry` and reads the display of a living owned creature, or zero if absent.
`spline_remaining_ms` reads the active native movement spline's remaining flight time in milliseconds, and
`spline_speed` reads its movement velocity in yards per second. Both return zero for a finalized spline.
`distance_2d` requires `target` and measures horizontal center distance.
`point_distance_2d` requires `x` and `y` and measures the horizontal distance from the unit to that point on its map.
`forced_forward` reads the server's force-movement flag; it does not simulate client movement or navigation.
`cast_remaining_ms` requires `spell` and returns its active cast/channel timer, or zero when inactive.
`cast_pushback_ms` reads the player's cumulative native cast-delay notifications, excluding elapsed cast time.
`weapon_damage_min` reads the calculated minimum damage, including weapon-dependent passive bonuses;
optional `hand` selects main hand (0, default), off hand (1), or ranged (2).
`spell_critical_damage` requires `spell` and `target` and calculates a critical hit from a fixed base of 1000,
including native critical damage modifiers, without executing an attack or applying mitigation.
`armor_reduced_damage` requires `spell` and `target` and applies native armor mitigation to a fixed base of
1000, including the attacker's armor penetration; optional `pet: true` selects the player's current pet.
It does not execute an attack.
`spell_uses_armor` separately checks whether the native damage path applies armor to `spell` and `effect`
(default 0), including spell school, armor bypass and bleed mechanics.
`aoe_damage_taken` applies native area damage avoidance to 1000 damage for `school` (0..6).
`reputation_gain` calculates a native spell reputation reward of 1000 for faction `id`, without granting it.
`spell_immune` and `spell_effect_immune` query native immunity against `spell` from `target`; the latter
accepts `effect` (default 0). These queries submit no attack.
`melee_attack_count` counts the actor's native melee combat packets, including extra attacks and misses.
`melee_damage_count` counts only those dealing positive damage. Both accept `hand` (0 main hand, 1 off hand).
`melee_damage_total` sums the positive melee damage in those packets and accepts the same hand filter.
These observations do not test delivery to a network client.
`spell_damage_count` and `spell_damage_total` require `spell` and count positive direct or periodic spell
damage events, or sum their post-mitigation damage, from the actor's native combat packets. Optional `target`
filters the victim, `pet: true` selects the actor's current pet as caster, and `critical` filters critical or
noncritical hits. Values accumulate throughout the scenario; use snapshots and `relative_to` around a cast.
They exclude zero damage, melee swing packets, and healing, and do not test network delivery.
`spell_heal_count`, `spell_heal_total` and `spell_effective_heal_total` similarly observe native direct and
periodic healing logs, counting positive heals, summing healing including overhealing, or summing effective
healing. They accept the same caster/critical filters; `target_pet: true` selects the current pet of a player
`target`. Absorbed healing is excluded. These metrics avoid confusing normal regeneration with spell healing.
The result's optional `cast_failures` array records native `SMSG_CAST_FAILED` spell IDs, cast counters and
numeric `SpellCastResult` reasons. These diagnose a rejected submission; effect assertions still establish success.
`distance` requires `target` and measures the native two-dimensional distance, in yards, between the actor and
that target. It reads position and nothing else, so displacement from a knockback, pull or teleport shows up as
the difference between two observations; take a `snapshot` first and assert `relative_to` it. Height is excluded.
`position_x`, `position_y` and `position_z` read the unit's native coordinates on its current map, so a
teleport's landing can be held to its destination with `min`/`max` bounds; pair them with `map_id`.
`in_flight` is 1 while a player rides a taxi and `taxi_destination` is the last node of the route still
ahead (0 when none). `discover_taxi_node` (player `actor`, TaxiNodes `entry`) marks a node discovered, as
talking to its flight master does, so a scenario can request a route through it.
`stabled_pet_count` counts a player's stabled pets, `pet_rows` counts their saved pets in `character_pet`
(only those saved in `character_pet.slot` `slot` when given)
and `stable_result` is the code of the last `SMSG_STABLE_RESULT` they received (0 before any).
`instance_binds_listed` decodes the player's last `SMSG_QUERY_INSTANCE_BINDS_RESULT` (0x06FE): the number of
binds it lists, only those on map `id` when given, or -1 when it carries another result than `_OK`.
`loot_count` and `loot_entry` accept `quality` to select only unlooted items of that exact quality in the open
loot window. `loot_required_level` and `loot_item_level` read those fields from the first matching item.
These values inspect generated loot through the native item template, without changing it.

`server_packets`, `server_packet_u8`, `server_packet_u32` and `server_packet_contains` accept `row` to capture
packets whose first 32-bit field is that value. Selected rows are retained independently of the ordinary
256-payload history limit,
including core opcodes. `server_packets` counts responses for that row; `server_packet_contains` returns 0 or 1
for text in its latest response. `server_packet_u32` also accepts a byte `offset` and `skip_strings`: skip that many
null-terminated strings at the offset, then read the 32-bit field at `index` relative to the resulting position.
For an item query response, `offset: 16, skip_strings: 4` skips the four item names; indexes 9 and 10 are
item level and required level. These observations cover server packet construction in socketless sessions.

`spell_proc_count` requires `spell` and counts the procs of that spell's aura on the actor since the scenario
started. What is counted is each spell the proc cast while the aura was named as its trigger, which is the one
place the server records both the proc and its owner; an aura whose proc does not cast anything counts zero.
Use it for a proc whose chance is below 100%, where a single roll proves nothing: cast the trigger often enough
that the false-failure probability is acceptable, and assert a `min` on the count.
`spell_cast_count` requires `spell` and counts the casts of that exact spell the actor completed since the scenario
started, triggered casts included. Use it where a script casts the effect directly, so no aura is named as the trigger
and `spell_proc_count` reads zero.
These two count metrics accept each other's snapshots with `relative_to`. Subtract an engraving aura's proc count
from its payload's total cast count to isolate a talent that casts the same payload without aura attribution.
`spell_proc_chance` requires `spell` and reads the loaded `spell_proc` Chance, after a zero is replaced by the DBC
ProcChance. `aura_proc_rate` requires `spell` (an aura on the actor), `target` and `type_mask` (proc flags), and runs
the aura's full proc decision, database filters, conditions, script CheckProc and the native chance roll, `trials`
times (default 40000) on one synthetic event. It reports the percentage that would proc, without running the proc.
The event deals 1000 damage, or 1000 effective healing with `heal`, from the actor to `target`, or from `target` to
the actor with `incoming`. `trigger_spell` names the event's spell; `hit_mask` (default 1, normal),
`spell_type_mask` (default damage, or heal) and `phase_mask` (default 2, hit) set the remaining event masks. Assert
a window around the expected chance; 40000 trials put six standard deviations inside 1.5 points.
Spell queries require `spell` and submit nothing: `spell_modifier` applies the player's native spell modifiers for
`op` (`SpellModOp`) to the number `base`; `spell_effect_value` (optional `effect`) returns the effect's value as the
player would cast it, including module base-value hooks; `spell_cast_time_ms`, `spell_max_range` and
`spell_max_stacks` return the modified native values; `spell_healing_done` requires `target` and optional
`effect`, with a fixed base of 1000. `spell_healing_done` and `spell_damage_done` accept `periodic: true`
to query the native periodic coefficient path instead of direct healing/damage.
`spell_effect_value` and `spell_damage_done` accept `pet: true` to calculate using the player's current pet.
For a player query, `spell_effect_value` accepts `flat_coefficient_modifier`: a temporary native
`SPELLMOD_BONUS_MULTIPLIER` in percentage points, restricted to that spell and removed after the query.
`melee_hit_chance` reads the player's melee hit modifier; `spell_hit_chance` reads a player or creature's native
spell hit modifier. `spell_power` (`school` 1..6) reads the player's base spell damage bonus.
`spell_done_crit_chance` and `melee_spell_damage_done` require `spell` and `target`: the native
crit chance for that spell, and the weapon-spell damage bonus from a fixed base of 1000. `spell_done_crit_chance`
only reflects native `ApplySpellMod(SPELLMOD_CRITICAL_CHANCE)` modifiers (a bare `Unit::SpellDoneCritChance` query);
it does not invoke `AllSpellScript::OnSpellCritChance`, which only runs mid-cast (`Spell::DoAllEffectOnTarget`).
`spell_done_crit_chance_scripted` requires the same `spell`/`target` and additionally runs that hook via a
throwaway, never-cast `Spell` instance, so a script-hook-only crit bonus is observable without a real cast.
`spell_taken_crit_chance` applies the target's native `SpellTakenCritChance` to the caster's done chance,
including target health and school conditions. It requires the same `spell` and `target`.
`aura_crit_chance` reads a
periodic aura effect's snapshotted crit chance; `aura_script_value` requires `key`. `script_melee_damage_taken`,
`script_spell_damage_taken` and `script_periodic_damage_taken` require `target` as the attacker (and `spell` for
the latter two) and return 1000 after the registered module damage-taken hooks. `script_heal_received` requires
`spell` and `target` as the healer and returns 1000 after the registered heal-received hooks, with the actor as recipient.
`set_health` also accepts a creature actor, or `pet: true` with a player actor to set its current pet's health.
`cast` also accepts a creature actor: the creature casts `spell` on `target` (itself by default) with
`TRIGGERED_FULL_MASK`, like `.cast back ... triggered`, and the step fails unless the cast starts.
`open_item` takes `actor` and `item` and submits the native container-open packet, offering it to the
packet hooks first as `WorldSession::Update` does. `close_loot` takes `actor`
and closes its current loot window. `collect_loot` takes `actor`, collects slot zero, verifies that its full rolled
quantity reached inventory and records the item/count. It supports ordinary container loot, not quest-only slots.
`loot_count` and `loot_entry` report the actor's current uncollected item slots and first entry; `loot_received`
reports the inventory increase from its last successful `collect_loot`. Closed windows return zero slots/entry.
The `loot_*` item metrics accept an optional `item` that keeps only the slots holding that item or a level-scaled
copy of it (entries 4400001 and up). `loot_item_armor` reads the first such slot's armor, and `loot_base_entry`
names the authored item a copy was made from. `carried_item_level`, `carried_item_required_level` and `carried_item_armor`
require `item` and return the highest item level, required level or armor among equipped and bagged items that are
that item or a copy of it, read from the item's own scaled template, or zero without one. `carried_item_scaling_level`
returns the highest per-item level that native item scaling stored for such an item, or zero when none was stored.
`loot_slot` with `item` also picks up a copy of that item.
`creature_loot_quality_rate` requires `entry` (a creature loot id), fills that template `rolls` times (default 10000)
for the actor and reports the percentage of fills holding an item of at least `quality` (default 3, rare).
`loot_slot` accepts an optional `item` to find that item in the current creature corpse's or chest's per-player
slots, then submits the native pickup request. Without it, `slot` defaults to zero. `respawn_remaining` reads a
fixture creature's remaining death-time respawn timer in seconds; summoned fixtures still use corpse-based timing.
`quest_rewarded` requires `quest` and reads the player's native rewarded status.
`has_achievement` requires `achievement` and reads whether the player has completed it.
`has_title` requires `title` (a CharTitles.dbc id) and reads whether the player has earned it.
`prepare_quest` takes `actor` and `quest`, adds the quest and required delivery items, then completes its objectives (unless `complete` is false, which leaves the quest in progress)
as fixture setup. `reward_quest` takes the same fields and optional zero-based `choice` (default 0); it checks normal
reward eligibility and invokes native reward delivery. These actions do not test quest-giver interaction or objectives.
`restore_quest_spells` takes `actor` and invokes the native restoration of spells from rewarded quests.
`action_button_packed` takes `button` and reads the complete action word, including its type.
`server_packet_u32` takes `opcode` and optional zero-based `index`, and decodes a word from the last
packet payload. It returns -1 when no such word was sent. These observe server state and packet contents.
`server_packet_u8` uses the same fields to decode a byte, with byte-sized indexes. It can inspect the result
byte in `SMSG_FRIEND_STATUS` (104) after a native `CMSG_ADD_FRIEND` (105) request.
`server_packet_float` uses the same fields to decode a finite IEEE 754 float. With `from_end: true`,
`index: 0` reads the last float and `index: 1` the preceding float, independent of a packed GUID's size.
The recorded core packets include duel request (359), countdown (695) and completion (362), and
`SMSG_MOVE_KNOCK_BACK` (239), whose final two floats are horizontal
speed and the negated vertical speed. These observations do not simulate client movement or keyboard input.
Besides the Ascension extension opcodes (0x520 and above), the recorded packets include the learned, superseded
and removed spell notices (299, 300 and 515) that the client prints to chat.

`relog` takes `actor`, commits the character through the native save path, logs it out, and reloads it
through the native character-login handler. It preserves saved character state and the scenario phase.
Optional `race` seeds the saved character's race through `CHAR_UPD_CHAR_RACE` and updates the character cache
before login, retaining saved pet data. This fixtures the post-service state; it does not submit a race/faction
service request or perform that service's spell, quest, faction, language or appearance conversions.
`race` reads the loaded unit's current race. `pet_native_display` reads the guardian's native display,
which the pet save path persists and transformation removal restores.

`login_hooks` takes `actor` and replays registered player-login hooks on the current character; it does not reconnect
or reload the character from the database. Use it to exercise a repair against deliberately seeded fixture state.
Hooks read character rows synchronously, so the step first waits for a marker query queued behind every character
database write already queued, as a real login's queries are; with several character database workers a write that
another worker is still running when the marker returns can remain uncommitted.
`persisted_action_button` requires `button` and returns the spell ID `Player::_SaveActions` writes for that action
button, or zero if it holds no spell.

`spellbook_loud_supersedes_for` requires `spell` and counts the `SMSG_SUPERCEDED_SPELL` notices that swapped that spell in
while the client still held it notable, the bit of its `SpellCustomAttr` row the "New Spell Learned" toast tests: no row
pushed yet, or the last one pushed carrying the bit. `spellbook_client_notable` reports the last pushed row's bit for
`spell`: 1, 0, or -1 when none was pushed.
`client_chat_lines_for` requires `spell` and counts the spell notices for it that the client prints to chat, following
Extensions.dll. A learned notice (299) is silent while the spell's last `SpellCustomAttr` row carries the quiet-learn
bit (0x40000 of the fourth attribute dword). A learned or superseded notice (300) is silent while a spell in it, or its
first rank, is listed by an indexed `SMSG_PATCH_CHARACTER_ADVANCEMENT` row (1610); a row is indexed by its second send
and every insertion of a new row clears that index; a learned or superseded notice is also silent while the added
spell's last Spell row is hidden. A learned or removed notice (515) is silent while the spell's last
`SMSG_PATCH_SPELL` row (2346) carries `SPELL_ATTR0_DO_NOT_DISPLAY` or `SPELL_ATTR0_IS_TRADESKILL`.
`client_placing_learns_for` counts the spell's learned notices sent while its last `SpellCustomAttr` row lacked the
no-placement bit (0x1000000 of the fourth attribute dword); up to level 10 the client places such a spell on an empty
button. `client_placing_supersedes_for` counts the superseded notices adding that spell while the Rank text of its last
`SMSG_PATCH_SPELL` row (the number in it) was 1 or less, or before any row was sent: up to level 10 the client places
such a spell on an empty button. `client_spell_rank_for` returns that number for the last row sent, or -1.
`client_removals_keeping_buttons_for` counts its removed notices ending in a zero byte, which Extensions.dll
answers without clearing the spell's action buttons. `client_spell_row_restored` returns 1 when the last two
`SMSG_PATCH_SPELL` rows for `spell` are the same row, first with `SPELL_ATTR0_DO_NOT_DISPLAY` and then without.
The model reads attributes only from rows the server sent, not from the client's own tables.
`temporary_spell_replacement` requires `spell` and returns the spell ID currently standing in for it on the
player's bars. `Player::GetTemporarySpellReplacement` returns the queried spell itself when nothing replaces
it, so the unreplaced reading is that spell's own ID, never zero. It reads server-side state, not what the
client draws.
`has_talent` requires the talent rank's spell ID; passive talents are separate from the learned spellbook.
`talent_points` measures unspent points in the active specialization.
`bank_bag_slots` measures the player's unlocked standard bank bag slots (0..7).
`pet_entry` measures the player's current guardian pet entry, or the entry of the companion it summoned
(a minipet, which never occupies the guardian slot), or zero if absent; `pet_display`, `pet_scale`
and `pet_is_banker` read the same unit, and `pet_distance` is its 2D distance from the player in yards.
`pet_knows_spell` requires `spell` and is 1 when that unit is a pet whose spellbook holds it.
`pet_spell_bar_count` counts nonempty spell entries in the current controllable pet's native action bar;
commands and reactions are excluded. It requires a pet with charm information and does not read rendered UI.
`bank_shows` counts the native bank windows the actor's session has been sent, which is what a
banker click is answered with. `system_messages` counts the chat lines the session has been sent.
`whispers_received` counts whispers the actor received from player `from` with exactly `text`.
`cast_failure` requires `spell` and reports the reason the client was told the last submitted cast of
that spell was refused, or zero if it was not refused since (the record is cleared when the scenario
submits that spell again).
`pet_aura_stacks`
requires `spell`, accepts `caster` for aura ownership, and returns zero if the pet or aura is absent.
`pet_aura_amount` and `pet_aura_amplitude_ms` accept `effect` and read its amount or tick interval.
`pet_aura_duration_ms` reads the same pet aura's remaining duration, and returns zero if the pet or aura is absent.
`spell_energize_count` and `spell_energize_total` observe native instant and periodic energize logs, excluding
ordinary regeneration. They require `spell`; optional `power`, `target`, `pet` and `target_pet` filter
resource type, recipient and current pets. The total is the logged nominal gain before the resource cap.

`pet_max_health`, `pet_attack_power` and `pet_run_speed_rate` read the current pet's totals and require a present pet.
`charm_entry` and `charm_aura_stacks` observe the player's charmed unit in the same way.
`controls_self` checks that the player's movement controller is their own character.
`private_instance` checks membership in a scripted private map such as Manastorm.
`dynamic_object` checks for the player's ground effect with the specified `spell`.
`dynamic_object_duration_ms` measures its remaining duration, or zero when absent.
`display_id` reads the unit's selected server display ID; it does not verify client rendering or animations.
`global_cooldown_ms` requires `spell` and reads the remaining native global cooldown for its recovery category.
Player commands retain normal permission and gameplay checks; verify their effects with assertions.
`owned_creature_count` requires a player and `entry`. It counts living creatures of that entry owned, created or summoned by
the player, in the same phase and within 100 yards, including summons outside the guardian-pet slot.
An optional `spell` restricts the count to creatures with that aura; `caster` can select its aura owner. `min_distance` keeps creatures at least that many yards from the player (2D), and `owner_display: true` those wearing the player's display.
`ranged_weapon_subclass` (0..20) restricts the count to creatures carrying a weapon of that item subclass
in their ranged virtual equipment slot; subclass 2 means bows. This observes server equipment, not client rendering.
`owned_creature_spacing` requires a player and `entry`. It reads the smallest 2D distance between two of those
living creatures, selected as `owned_creature_count` does, or zero when fewer than two are present.
`owned_creature_visible` requires a player and `entry` and reads one matching summon's server visibility,
returning zero when absent. Pair it with a count assertion when checking a hidden helper.
`owned_creature_spell_hit_chance` requires a player and a present owned creature selected by `entry`.
It reads that creature's native spell hit modifier. `set_aura` accepts `owned_entry` to select the same type
of owned creature within 100 yards and the player's phase; it cannot also select `pet: true`.
`owned_creature_attackable` requires the owning player, a present creature `entry` and a `target` unit.
It reads whether that target can attack the summon through the native `IsValidAttackTarget` check.
`owned_creature_victim` requires the owning player, a present creature `entry` and a `target` unit.
It returns one while that unit is the summon's current victim.
`pet_casting` requires the player's present native pet and reads its casting flag and active non-melee spell.
Use it to observe channel completion before submitting another ordinary pet cast;
aura expiry is a separate event.

`owned_creature_weapon_damage_min` requires a player and `entry`. It returns the lowest minimum weapon damage (`UNIT_FIELD_MINDAMAGE`) across their living
owned creatures of that entry in the same phase and within 100 yards, so every copy of a guardian must meet an asserted `min`; zero when there are none.
`owned_gameobject_count` requires a player and `entry`. It counts their summoned gameobjects of that entry
in the same phase and within 100 yards. `gameobject_display` and `gameobject_scale` read the single owned
object's native display id and scale, returning zero when absent. They do not verify client rendering.
`gameobject_remaining_ms` uses the same lookup and requires exactly
one object when present; it returns the remaining lifetime with one-second precision, zero when absent,
or -1 for an object without an expiry. Moving out of range is not proof of despawn.
`at_homebind` checks that the player is on their homebind map and within five yards of its position.
`use_gameobject` keeps normal interaction-distance and usability checks. It does not inspect a rendered UI.
The [portable gadgets scenario](scenarios/portable-gadgets.json) checks item summons, lifetimes, portal
teleports and expiry. It requires `mod-portablemail`; mailbox and altar client interfaces are not tested.
`power`/`max_power` and `pet_power`/`pet_max_power` accept a numeric `power` (0..6).
`mana_regen` and `mana_regen_interrupted` read the player's owner-visible mana regeneration fields in
mana per second, outside and inside the five-second rule. `resting` reads the native resting player flag.
`sent_mana_regen` and `sent_mana_regen_interrupted` decode those fields from native values-update packets
received by the owner's session, returning -1 until the field has been observed. These metrics do not
inspect a rendered resource bar.
The pet queries require a player with a current pet. Aura metrics optionally accept `caster` to select
ownership; `aura_visible` observes whether the native aura application occupies a client-visible buff slot.
`aura_amount` also accepts an effect index (0..2, default 0). Missing auras yield zero;
check aura presence separately when zero is a valid effect amount. Permanent aura duration is -1.

### Destiny Weaver regressions

`scenarios/destiny-weaver-scaling.json` checks deferred scaling choices, armor debuffs, creature values
updates after level changes, fractional damage accumulation, and ordinary damage with scaling off.
It requires `DestinyWeaver.Enable=1`, `DestinyWeaver.LevelScaling=1`, `DestinyWeaver.Scaling.Offset=4`,
and `CoA.QuestLevelScaling=1`. Spell 705798 supplies one base damage without critical hits;
Faerie Fire (770) supplies a 5% armor reduction. Spell 705798 uses melee hit resolution, so the fixture
sets melee hit and expertise as well as spell hit. Template 1501 has HealthModifier 0.93: the level-1
fixture's real pool remains 40 HP while its level-55 view has 2,432 HP. Ten one-damage hits cannot remove
a whole real HP; 67 remove one.

`scenarios/skinning-dungeon-scaled-view.json` and `scenarios/skinning-open-world-level-scaling.json` need the
same settings: the skinning requirement follows a view that lowers a dungeon creature, never one that lifts it.

`scenarios/destiny-weaver-quest-fallback.json` requires a separate run with `DestinyWeaver.Enable=0`
and `CoA.QuestLevelScaling=1`. Quest 7 must still follow its QuestTemplateScaling.dbc row to level 20 and
award XP.

The `level_scaling_packet` action takes a player `actor` and `value` (0 or 1). It sends the existing
four-byte request through the early packet hook on a worker, verifies that player state has not changed
before a player update, then leaves subsequent assertions to verify the queued choice took effect.
It tests dispatch and deferral, not a real socket, packet delivery, or every possible concurrent schedule.

`view_level` takes a player `actor` and unit `target` and queries the target-relative combat level.
`sent_level` and `sent_max_health` use the same fields and observe values-only object updates emitted to
the socketless session. They return zero until the corresponding field has been observed; they do not
force updates or inspect client rendering. `lfg_dungeon_disabled` takes an LFGDungeons.dbc `dungeon` id and
returns 1 when the `disables` table locks that dungeon's map and difficulty out of Dungeon Finder, otherwise 0.
`lfg_state` takes a player `actor` and returns its native Dungeon Finder state (0 none, 1 role check, 2 queued,
3 proposal, 4 vote kick, 5 in dungeon, 6 finished dungeon, 7 raid browser).
`creature_query_rank` takes a player `actor` and creature `entry` and returns the rank of the
last creature query response delivered to that session, or -1 before one arrives.
`quest_level` and `quest_xp` take a player `actor` and `quest`
and query the native quest level and XP calculations without awarding a reward.
`quest_log_sent_level` and `quest_log_sent_xp` take the same arguments and return the last level or reward XP
sent for that quest's log slot in `SMSG_UPDATE_OBJECT_ADDON` (fields 61 and 36 + slot), or -1 before one arrives.
`quest_offer_sent_xp` reads the reward XP in the last native `SMSG_QUESTGIVER_OFFER_REWARD` for that quest,
or -1 before the session receives a reward offer.
`quest_query_scaled` takes the same arguments and returns 1 when the last quest query response for that quest
carried the client's scaled-quest flag `0x01000000`, 0 when it did not, or -1 before one arrives.
`quest_query_reward_choice` takes the same arguments and returns the first choice reward item id in the last quest
query response for that quest, or -1 before one arrives.

`dungeon_difficulty_packet` takes a player `actor` and `value` (0, 1 or 2), sends the native dungeon
selection packet through the packet hook and typed session handler, and does not bypass its group or
in-instance restrictions. `map_id` and `map_difficulty` observe the current map after a normal teleport.
`nearby_creature_template` requires `entry` and exactly one creature within 60 yards, then returns its
selected difficulty template. `loot_gear_item_level` returns the first unlooted weapon/armor item's level in
the current loot window (zero if absent). The three `vanilla-dungeons-*` scenarios use these to check
all 19 map/mode pairs per tier and a real VanCleef killing blow, without a GM access bypass.
`nearby_gameobject_state` takes `entry` and returns the state of the nearest such gameobject within 20 yards
(0 open, 1 closed, 99 none).
## Evidence boundaries

### Optional character names

`scenarios/optional-character-names.json` creates a single-word character, two characters sharing its
first name, and a 25-character full name through normal creation and login handlers. Player fixtures
accept an optional `name`. `player_name` compares the loaded name with the supplied `name` (0/1);
`name_lookup` checks online and character-cache resolution against the actor (0/1). Who assertions
inspect native response packets. These checks require the corresponding server build and SQL update;
they do not validate native client input, rendering, or transport.

The test owns socketless sessions outside the network session manager. Map updates and normal spell/item
handlers execute; character database loading and login hooks execute. Authentication, transport encryption,
network session discovery, actual client packets, rendering, tooltips and UI input are outside this mode's
coverage. Transfers receive synthetic client acknowledgements. Movement/navigation, reconnect and restart
scenarios need additional driver support.

Health and power observations are net state changes. They include regeneration, absorbs, intervening procs
and other effects; they are not per-spell combat-log measurements. Control fixture conditions and use expected
ranges where appropriate. The bundled Frostbolt scenario tests behavior, not exact damage coefficients.
Random proc-rate claims require enough independent trials and a statistical assertion; this version does
not provide an automatic statistical test. Keep intended values independent of the implementation under test.

## Runner checks

```sh
python -B tools/verify_all.py --stages source
```

The source stage's `gameplay` suite runs the runner, batch, world-cache and verification tests and
`catalog.py --check`; with `--base`, it is selected when gameplay tooling, scenarios or the runtime component
change. Runner checks cover invalid scenarios, incorrect/partial results, owned-process timeouts, isolation,
partial-clone cleanup, cache reuse/invalidation, ownership and exclusive leases, and the queue protocol with a
fake server. They do not substitute for building and running the native scenario.

`spell_go_count` counts the actor's native `SMSG_SPELL_GO` packets for `spell`; optional `pet: true`
selects the current pet, and `entry` instead counts the packets the actor received from any creature of that
template, such as its own summoned wards, which are neither pets nor fixtures. Other lanes' creatures are in other
phases, so `entry` counts only creatures the case's players can see. Invisible triggered spells may omit this
packet. A cast count proves dispatch, so pair it with effect assertions. It does not test network delivery or
client rendering.
`spell_hit_bonus_taken` reads the victim aura contribution to the native spell hit calculation for `spell`.
`rooted` reads the unit's native root state. `spell_healing_taken` queries incoming healing from `target`
with a base amount of 1000 and requires `spell`; `periodic: true` selects the native HoT path.

`stealth_detection` reads native general stealth detection. `can_detect` requires `target` and invokes
the observer's native `CanSeeOrDetect` check; neither metric covers client rendering.

`ascension_dungeon_difficulty_packet` sends the one-byte Ascension portrait-menu request through the
real early receive hook and session queue; follow it with a wait before teleporting. The native
`dungeon_difficulty_packet` remains available for Normal and Heroic. `nearby_creature_max_health`
requires an entry and reads the nearest living matching creature within 60 yards. The
`vanilla-dungeons-health` scenario uses real spawns to check video HP, explicitly inferred HP and
unchanged Normal health. It does not establish the original Ascension scaling formula.
