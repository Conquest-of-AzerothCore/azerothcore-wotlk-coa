# 0581. Behaviour kinds are modules discovered at run time

- Status: accepted
- Date: 2026-11-13

## Context

A new behaviour kind touches about ten shared places: the `KINDS` tuple (`behaviours.py`), a branch of
`behaviour_scenario` (72 branches), a branch of `compare.judged_behaviour`, a row of `passives.BEHAVIOUR_LABELS`,
sometimes the `coverage` tables and the pooled judge, a test class at the tail of `test_behaviours.py` and a section
at the tail of `docs/behaviour-scenarios.md`. Two class authors adding kinds at the same time edit the same lines
(requirement 3 of the contributor-structure plan). `cast_period.py` (ADR 0535) already kept four kinds in their own
module behind lazy imports, because it imports `behaviours` itself.

## Options

1. Keep the central chains and tails (status quo).
2. A registry that each kind module calls at import time.
3. A package `kinds/` whose modules are found with `pkgutil.iter_modules` on first use and consulted before the
   existing chains.

## Decision

Option 3. Option 2 is unsafe: a kind module imports `behaviours` and `compare`, which would have to import the module
to register it.

- `kinds/<kind>.py` states `KIND`, `ORDER`, `scenario(class_file, entry)` and, when it has them, `JUDGES`
  (`{check: judge}` for models whose `kind` is `KIND`), `POOLED_JUDGE`, `label(entry)` and `EVIDENCE`,
  `METRIC_EVIDENCE`, `STATE_PROMISES` rows. `kinds/__init__.py` imports the modules (not `test_*`) on the first call
  and caches them.
- Hook points, each consulted before the existing chain: `behaviours.behaviour_kinds()` (the literal `KINDS`
  followed by the discovered kinds sorted by `ORDER`, used by `behaviour_entry` and `packets.py`),
  `behaviour_scenario`, `compare.judged_behaviour`, the pooled-parts judge of `compare.evaluate`,
  `passives.behaviour_label`, and `coverage.evidence_classes()`, `metric_evidence()` and `state_promises()`. The
  merged tables stay closed: a kind whose check or metric has no row fails as before (ADR 0120).
- `ORDER` keeps `behaviour_kinds()` equal to the former tuple, so the kind list `packets.py` prints is unchanged;
  the Necromancer kinds keep their former positions (1 to 12, from `npc_repair` to `energize_range`), and a new kind
  takes the next number. Equal numbers sort by name.
- Tests of a kind are `kinds/test_<kind>.py`, discovered by `test_kinds.py`, the one `conformance` suite command, so
  a new kind does not edit `tools/check_source.py`. `test_kinds.py` imports every module (an import error shows in
  the source stage, not first at generation), checks that no discovered kind is also built in and that every module
  has a test file. A kind's page is `docs/kinds/<kind>.md`; `docs/behaviour-scenarios.md` keeps the index.
- Templar kinds stay where they are; the Necromancer kinds move one commit at a time, each commit keeping
  `generate --class 19`, `--stack` and `--class 23` byte-identical.

## Consequences

- A kind is added by one module, one test file and one page, plus its class-file entries; shared files change only
  for a new shared helper or a new check.
- A kind module depends on the helpers of `behaviours.py` and `compare.py` it imports; moving one of them breaks the
  module's import, which `test_kinds.py` reports.
- The lookup is a module attribute, so a typing error in a module (no `scenario`, a judge under the wrong check)
  shows only in that kind's tests or generation.
