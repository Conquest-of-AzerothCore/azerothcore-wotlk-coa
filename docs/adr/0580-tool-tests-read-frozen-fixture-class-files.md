# 0580. Tool tests read frozen fixture class files

- Status: accepted
- Date: 2026-11-13

## Context

The conformance tool tests read the live class files under `apps/coa-gameplay-test/conformance/classes/`. A class
author who edits an entry of `templar.json` or `necromancer.json` then breaks tool tests that only use the file as
sample data, and a tool change has to be checked against data that moves under it. The contributor-structure plan
(requirement 4) asks for tool tests that do not depend on a class's live file; the mentor ruled full frozen copies
(open decision 4).

## Options

1. Keep reading the live files (status quo).
2. Full frozen copies under `conformance/fixtures/classes/`, read by a separate loader.
3. Copies trimmed to the entries the tests use.

## Decision

Option 2.

- `conformance/fixtures/classes/templar.json` and `templar_clauses.json` are byte copies of the live files at
  1a39df83b7. The fixture directory is outside `classes/`, so `class_file_paths()`, the generator and the catalog
  never see it.
- `profile.load_fixture_class_file(class_id)` reads only that directory. It shares `class_file_among` with
  `load_class_file`, so a fixture naming a `dbc_dir` still has to be the server set (the tests already depended on
  it; a DBC-less test still skips as before).
- Every tool test that reads Templar data reads the fixture: the module-level `CLASS_FILE`s, the
  `load_fixture_class_file(...)` calls, and every `generate` or `main(['generate'|'packets', ...])` call, which runs
  under `mock.patch('conformance.load_class_file', load_fixture_class_file)` (`test_compare.fixture_generate`).
- The Necromancer fixtures (`necromancer.json`, `necromancer_clauses.json`) are byte copies of the live files taken
  after the ADR citation rewrite (contributor-structure step 2, ADR 0583); every class-23 read in a tool test reads
  them, `main(['generate', '--class', '23', ...])` under the same patch.
- Tests that read every live class file on purpose stay live and carry `cross_class_guard` in their name:
  `test_coverage.py` (consumption files are not class files; every metric of every class file has an evidence class;
  every metric-classed expectation carries its metric; every class ledger is well formed), `test_values.py` (every
  class file names its class; the ledger is not a class file; an unknown class is refused) and `test_questions.py`
  (the live `templar.json` text settles from logs).

## Consequences

- A Templar class-file edit no longer changes a tool test outcome, except through a cross-class guard.
- The copies duplicate about 2.6 MB and do not follow later format changes of the live files; a format change
  updates the fixture in the same commit. The schema of the live files is still validated by generation and the
  guards.
- A new tool test reads `load_fixture_class_file` or a fixture path; `load_class_file(` in a tool test is either a
  cross-class guard.
