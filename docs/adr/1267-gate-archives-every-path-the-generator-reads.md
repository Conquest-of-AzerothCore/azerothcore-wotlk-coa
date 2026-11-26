# 1267. Gate archives every path the generator reads

- Status: proposed
- Date: 2026-11-24
- Decided by: mentor decision D-88 (owner delegation O-12).

## Context

The cycle gate (`cycle.py`, step `gate`) regenerates every finished class from a `git archive` of the base commit
and compares it with the head. `DEFAULT_GATE_PATHS` archived `apps`, `src` and `data/sql/updates` only. The
bonus-data reader (`bonus_data.py`) also reads `data/coa-world/baseline.json` and its zip, falls back to
`data/sql/base/db_world` without that manifest, walks the `updates_include` directories `data/sql/archive/db_world`
and `data/sql/custom/db_world`, and reads `modules/*/data/sql/*world*`. A missing input empties the table without an
error, so the base tree generated 2294 Templar scenarios against 2301 at the head (Felsworn class-end gate, bisect19
note), and the gate reported a change that no commit made.

## Options

- Archive the whole `data` directory and `modules`. Rejected: `data/sql/old` (4120 files) and `data/sql/create` are
  never read by the generator.
- Add each read path to `DEFAULT_GATE_PATHS`, and guard it with a test that audits a real generation.
- Make the bonus-data reader fail on a missing input. Left as a tool gap: it changes what a generation does on an
  incomplete tree, which is a separate decision.

## Decision

`DEFAULT_GATE_PATHS` lists `apps`, `src`, `data/sql/updates`, `data/sql/archive`, `data/sql/base`,
`data/sql/custom`, `data/coa-world` and `modules`. `data/sql/base` is listed from code reading
(`bonus_data.base_world`): the generator reads it only when `data/coa-world/baseline.json` is absent.

`test_cycle.py` runs `conformance.py generate --class 19 --spell 570233` under a Python audit hook, keeps the
`open`, `os.listdir` and `os.scandir` targets inside the repository that Git tracks (an archive cannot carry
untracked files), and fails on any read outside `DEFAULT_GATE_PATHS`. That generation reaches the same read roots as
the full generations of classes 15, 19, 19 `--stack`, 23 and 27 (audited when this ADR was written) in about
7 seconds. The former paths are kept in the test as the mutant: they must leave `data/coa-world/baseline.json`
uncovered.

## Consequences

- A pair's `gate_archive_paths` in `cycle.json` still overrides the default.
- The gate's base tree is larger (3363 more tracked files at 97dc698223, mostly `data/sql/archive` and `modules`).
- Generated scenarios do not change: the gate only reads the base tree, and the head generations are byte-identical
  before and after.
- A new loader whose reads the audited generation does not reach is not caught by the test; the audit covers one
  hit spell's generation path.
