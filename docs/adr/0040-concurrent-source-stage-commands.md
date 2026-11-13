# 0040. Concurrent `check_source.py` commands, and process-shared DBC derived-table caches

- Status: accepted
- Date: 2026-11-09

## Context

The `source` stage of `tools/verify_all.py` gates every CoA conformance change and ran over a hundred times in
two days at about 330 s wall time. `tools/check_source.py` ran its ~39 selected commands strictly one after
another (`source.log` of a measured run: sum of per-command `seconds` equalled the wall time), and the four
slowest commands were conformance test files: `conformance/test_hits.py` (111.2 s), `conformance/test_values.py`
(103.8 s), `apps/coa-gameplay-test/test_batch.py` (37.6 s) and `conformance/test_passives.py` (36.3 s).

## Root cause of the slow conformance tests

Profiling (`cProfile`, isolated per test method) showed the conformance suite's cost was not DBC parsing itself
(`inspect_dbc.DataSet.load` already caches a loaded table per `DataSet` instance, and `values.py` already
`lru_cache`s `DataSet` construction by directory). It was two kinds of **derived-table cache loss across
short-lived objects that wrap the same, already-loaded `DataSet`**:

1. `tooltip.Records.__init__` (`apps/coa-gameplay-test/conformance/tooltip.py:114`) reset `self.raw`,
   `self.ability_index` and `self.weapon_skills` to empty on every instantiation. `hits.rolled_values`
   (`conformance/hits.py:309`) constructs a fresh `ForcedPoints(records.dbc, ...)` — a `Records` subclass — for
   *every die roll* (up to `RECKONING_DIE_SIDES` = 49, `RIGHTEOUS_UPHEAVAL`'s 335, etc.), and each one recomputed
   `weapon_skill_spells()` (`tooltip.py:243`, a full scan of the ~210k-row `Spell` table) and `abilities()`
   (`tooltip.py:165`, a full scan of `SkillLineAbility`) from scratch, even though the underlying `DataSet` —
   and therefore the correct result — was identical every time. `cProfile` on
   `test_vindication_equips_the_one_hand_weapon` alone showed 46.9M calls to `DataSet.value`/`struct.unpack_from`
   across 51.9 s, almost all inside `weapon_skill_spells` (180 calls, 37.6 s cumulative) and `abilities` (360
   calls, 17.1 s cumulative).
2. `classes.class_spells` (`conformance/classes.py:71`, used by `test_passives.py`'s
   `test_every_custom_class_classifies` once per CoA class) and `classes.class_skill_lines` each constructed a
   fresh `DataSet(dbc_dir)` and then read `Spell` through `classes.table_rows`
   (`conformance/classes.py:34`), which decodes **every** row of the table and only *afterwards* filters down to
   the handful of wanted spell ids — for `class_spells` that is 3 fields × ~210k rows per call, repeated once per
   class.
   `passives.family_spells` (`conformance/passives.py`, pre-fix) had the same one-field-per-class full-table-scan
   shape for `SpellFamilyName`/`SpellName[enUS]`, run once per class even though every class's scan reads the
   exact same table.

None of this duplicated I/O (the OS page cache keeps `Spell.dbc`'s bytes warm), but every `DataSet.load`-adjacent
scan re-did the CPU-bound `struct.unpack_from` decode, matching, and dict-building work in full.

## Decision

1. **Hoist the `Records` derived-table caches (`raw`, `ability_index`, `weapon_skills`) from per-instance state
   to a process-wide cache keyed by the underlying `DataSet` object** (`tooltip.DERIVED_TABLE_CACHE`, a
   `weakref.WeakKeyDictionary`). The cached data (raw `SkillLineAbility`/`CharBaseInfo`/`SkillRaceClassInfo`/
   `ItemSubClass` rows, and the weapon-skill-spell index) is a pure function of the DBC content the `DataSet`
   wraps and does not depend on any instance override (`ForcedPoints`/`ScaledPeriod` only override specific
   `Spell` effect-point reads, never these raw tables), so sharing it across every `Records`/`ForcedPoints`/
   `ScaledPeriod` instance built on the same `DataSet` — including the thousands of ephemeral ones created inside
   `rolled_values`'s roll loop — changes no test's observed values, only how many times they are recomputed.
   `classes.dataset()` gained an `@lru_cache(maxsize=None)` keyed by directory (moved from `values.py`, which now
   imports it from `classes` to avoid duplicating the cache and the circular import it would create), and
   `class_spells`/`class_skill_lines` now call it instead of constructing a fresh `DataSet` each time.
2. **Replace `classes.class_spells`'s whole-table `Spell` scan with an identity-keyed lookup**
   (`classes.rows_by_identity`): since the caller already knows the exact wanted spell ids, there is no need to
   decode every unrelated row. `table_rows` itself is unchanged and still used where no identity filter is
   possible (`CharacterAdvancementClassTypes`, `CharacterAdvancement`).
3. **Split `passives.family_spells`'s single-pass full scan from its per-family lookup**
   (`passives.spell_names_by_family`, `@lru_cache(maxsize=None)` keyed by the `DataSet`): one scan of the `Spell`
   table groups every spell name by `SpellFamilyName` once per `DataSet`; `family_spells` then does an O(1) dict
   lookup per family and only computes `family_flags` (itself a handful of indexed `Spell` reads) for the spells
   that actually belong to the requested family, exactly as before.
4. **Run `check_source.py`'s independent commands with a bounded `ThreadPoolExecutor`**
   (`tools/check_source.py`'s `execute`), default `os.cpu_count()` workers, overridable with `--jobs`.
   `ThreadPoolExecutor.map` preserves input order in its results, so the JSON report's `results` list stays in
   the same order as `commands` regardless of which command finishes first; a command's `subprocess.run` failure
   or timeout is still caught and recorded exactly as before (`run_command` is the same per-command body, now
   called from a worker thread instead of the main thread), and the aggregate `status` is still `'failed'` if any
   command failed.

## Why every command was safe to parallelize, nothing stays serialized

Every command under `SUITES` and the two always-run commands (`check_change_boundaries.py`,
`check_comments.py`) were read against this question: fixed temp paths, a shared database, a bound port, or
files written into the tree outside a per-test temporary directory.

- All of `apps/coa-gameplay-test/{test_batch,test_runner,test_verification,test_world_cache}.py`,
  `apps/coa-dbc/{test_client_dbc,test_inspector,test_capture_sql}.py`,
  `apps/coa-world-content/{test_validate_content,test_archive}.py` and `apps/codestyle/tests/test_scoped_lint.py`
  build their fixtures in a fresh `tempfile.TemporaryDirectory()`/`mkdtemp()` per test, with a fake worldserver,
  `mysql` and `mysqldump` binary under that directory; the "Preparing reusable world database" message this
  stage's test_batch.py and test_verification.py can print comes from exercising `world_cache.py`'s code path
  against those fakes, not a real MySQL server, so there is no real shared database or port to collide on.
  `run.unused_port()` only reads back a free port number from a socket it immediately closes; nothing later
  binds it for real inside these unit tests, so two processes picking the same number has no effect.
- `check_change_boundaries.py`/`check_comments.py` and the lint/content/mechanics/registration checks only run
  read-only `git` subcommands (`diff`, `show`, `ls-files`) and read-only filesystem scans; they write nothing
  into the tree.
- `conformance`'s tests read the shared, read-only `/srv/coa/server-data/dbc` directory; the new
  process-wide caches this ADR adds are all keyed by the `DataSet` object (or its directory), so concurrent
  commands — each its own subprocess with its own fresh caches — never share or race on that state; within one
  command's process the caches are populated once and read repeatedly, same as before this change but shared
  across more call sites.
- Concurrent CPython bytecode caching (`__pycache__`) is a known-safe write-temp-then-rename pattern; two
  processes compiling the same module at once do not corrupt each other's `.pyc`.

No exclusive group was found or declared. Five consecutive `--all` runs under the new `ThreadPoolExecutor`
produced the same single (pre-existing, confirmed unrelated to this change) failure each time —
`tools/test_comments.py`, which already fails serially against this worktree — and no new or flaky failure, so
every command stays in the single concurrent pool.

## Consequences

- Wall time of `python -B tools/check_source.py --all`: ~330 s (serial, before) → ~88 s (after the cache fixes
  alone, still serial) → ~38 s (after also running concurrently; close to the stage's single slowest command,
  `test_batch.py`, which is dominated by real thread/grace-period waits rather than CPU and was left untouched
  because shortening those waits would weaken the concurrency/timeout behaviour those tests exist to verify).
- `tools/test_source.py` gained tests for order preservation under concurrency, the `--jobs` default/override and
  continued failure reporting; the existing mock-based sequential test now pins `jobs=1` so its ordered
  `side_effect` list stays deterministic.
- `docs/coa/verification.md`'s `source` stage description now states it runs concurrently and that its wall time
  tracks its slowest command, not the sum of all of them.

## Considered options

- Leave `check_source.py` serial and only fix the DBC caches. Rejected: still leaves `test_batch.py`'s ~38 s of
  real time, and every other command's few seconds, fully on the critical path for no reason, when nothing
  prevents running them together.
- Add a declared "exclusive" suite flag in `SUITES` for a cautious first cut, serializing anything not proven
  safe. Rejected: the audit above found no command with shared fixed state to protect; adding the flag with
  nothing assigned to it would be unused machinery.
