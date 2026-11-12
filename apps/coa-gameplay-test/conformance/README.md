# CoA class tooltip conformance

Python 3.11+ standard library only. Tools that check, per class, that spells behave as their client tooltip says.
Expected values come from the effective client DBC set (`/srv/coa/server-data/dbc`), never from server code.

## Quick start

```sh
cd apps/coa-gameplay-test/conformance
python3 -B conformance.py generate --class 19 --out DIR [--spell ID ...] [--passive ID ...] [--proc AURA ...] \
  [--trigger AURA ...] [--behaviour SPELL ...] [--target-gate SPELL ...] [--learned-hit SPELL ...] \
  [--stack [--passes N]] [--controls]
python -B ../../../tools/verify_all.py --stages gameplay --scenario DIR/scenarios/*.json
python3 -B conformance.py compare --manifest DIR/manifest.json --results .cache/verify-all/STAMP [--out OUT] \
  [--build BUILD]
```

`generate` writes the scenarios and a manifest for one class (or a `--spell`/`--passive`/`--proc`/`--trigger`
subset); the gameplay stage of `verify_all.py` runs them; `compare` judges the results against the manifest and
writes `alerts.tsv`, `report.md`, `verdicts.json` and `questions.md`. Full command reference, output files and
flags: [Generate and compare](docs/generate-and-compare.md).

## A full class run

`--stack` selects only the talent stack, so a class takes two manifests. From this directory, with `W` the
worktree:

```sh
python3 -B conformance.py generate --class 19 --out $W/.cache/conformance/templar
python3 -B conformance.py generate --class 19 --stack --out $W/.cache/conformance/templar/stack
python -B $W/tools/verify_all.py --stages gameplay --scenario $W/.cache/conformance/templar/scenarios/*.json
python -B $W/tools/verify_all.py --stages gameplay --scenario $W/.cache/conformance/templar/stack/scenarios/*.json
python3 -B conformance.py compare --manifest $W/.cache/conformance/templar/manifest.json \
  --results $W/.cache/verify-all/STAMP --out OUT
python3 -B conformance.py compare --manifest $W/.cache/conformance/templar/stack/manifest.json \
  --results $W/.cache/verify-all/STACK_STAMP --out OUT/stack
```

The runs end `INCOMPLETE` (exploratory scenarios leave the gameplay stage `unavailable` even when every scenario
passes); the gameplay line of the run gives the passed/failed counts. Keep the outputs outside Git
(`.agents/plans/class-conformance/<class>/`). Past run sizes, timings and fix-round history:
[Generate and compare § A full class run](docs/generate-and-compare.md#a-full-class-run).

## Method rule

No server change whose only evidence is our own check: a server fix cites the tooltip text, the Ascension logs or an
owner ruling (owner, 2026-11-11; ADR 0128). A conformance alert is a lead, not evidence. Every server-fix item of a
round uses the [server-fix brief](docs/fix-brief.md).

## Where to find what

Each topic lives in its own page under `docs/`, so an agent reads only the page it needs:

- [Class conformance guide](../../../docs/coa/class-conformance.md) — the contributor workflow for taking one class
  through tooltip → behaviour proof, and its [rulings](../../../docs/coa/class-conformance-rulings.md).
- [Class map](docs/class-map.md) — `class_map.py`, the per-spell risk map of all 21 classes that starts a class's
  work.
- [Conformance modules](docs/modules.md) — one-line responsibility of every `.py` module.
- [Class spell sets](docs/spell-sets.md) — `class_spells`, ranks, and extra (non-progression) class spells.
- [Tooltip reading](docs/tooltip-reading.md) — `$`-token parsing, level-scaled and per-level points, `$<name>`
  references.
- [Reference character](docs/reference-character.md) — the fixed character a class file measures against.
- [Value scenarios (no-combat)](docs/value-scenarios.md) — the no-combat scenario of one rank.
- [Passive effects](docs/passive-effects.md) — effect classification, overrides, conditional tooltips, modifier
  targets, phrase checks, the passive with/without scenario.
- [Max-rank hit scenarios](docs/hit-scenarios.md) — the hit/melee scenario of a spell's highest rank.
- [Proc rates](docs/proc-rates.md) — proc entries, procs per trigger (ADR 0130), the two-reading/Ascension-log fallback,
  nested proc rates.
- [Trigger entries](docs/trigger-entries.md) — always-on triggers, taken-hit, cooldown-delta, duration-delta
  entries.
- [Behaviour scenarios](docs/behaviour-scenarios.md) — prose-only behaviours: target count, healing ratio, aura
  spread, shield break, metric delta, health-threshold ratio, leech ratio, duration, duration ratio, duration
  refresh, amount delta, expiry pairs, Templar entries.
- [Player observations and readings](docs/player-observations.md) — a class file's `player_observations` and
  `player_tooltip_readings` arrays.
- [Talent stack (lever map)](docs/talent-stack.md) — cumulative talent configurations, DPS levers, the owner
  fallback for an ambiguous tooltip.
- [Scaffolding a class file](docs/scaffolding.md) — `conformance.py scaffold`, what it fills in and what it
  leaves for a human.
- [Generate and compare](docs/generate-and-compare.md) — `generate`/`compare` CLI, a full class run, the impact
  report, coverage comparison, behaviour sheets, the `prove` runner, batch samples, per-spell packets, verdict
  statuses, open conformance checks.
- [Server-fix brief](docs/fix-brief.md) — the method rule for server fixes and the brief template round workflows
  copy into each fix item.
- [Clause ledger and clause coverage](docs/clause-ledger.md) — `classes/<name>_clauses.json` format, how a
  workstream contributes labels, `conformance.py coverage --clauses`, the behaviour-proven and data-conformant
  statuses, tool gaps and the `Spell.dbc` sha256 of fragments.

## Run

Tests run through `verify_all` only; the `conformance` suite of `tools/check_source.py` lists them.

```sh
python -B tools/verify_all.py --stages source --base origin/main
```

The tests that read the client DBC set are skipped when `/srv/coa/server-data/dbc` does not exist; the fixture tests
always run.
