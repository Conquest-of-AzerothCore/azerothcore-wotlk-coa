# 0582. Metric-delta options are modules

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0581

## Context

`MetricDeltaSpec` (`behaviours.py`) has 62 fields, read positionally by `metric_delta_spec` and checked and applied
inside `metric_delta_scenario` (about 380 lines). Most Necromancer ADRs added one field, so every option touched the
dataclass, the positional parser, the check chain and the scenario body: the most edited lines of the tool. A kind
module (ADR 0581) does not help, since the options belong to one kind. The mentor ruled to take the options out of
the central edit point (contributor-structure open decision 5).

## Options

1. Keep the dataclass; append each new option at its end with a shared ADR (residual risk).
2. Option modules that own their field, its parsing, its checks and what it adds at named points of
   `metric_delta_scenario`.

## Decision

Option 2, for new options and, as the first two, `corpse` (ADR 0493) and `player_spell_power` (ADR 0364).

- `metric_delta_options/<field>.py` states `NAME`, `ORDER` and `parse(raw)`, and optionally `check(spec, value)` and
  `fixtures(class_file, spec, value, scenario)`. `metric_delta_options/__init__.py` finds the modules with
  `pkgutil.iter_modules` on first use.
- `metric_delta_spec` stores the parsed values of the options an entry names in `MetricDeltaSpec.options` (pairs in
  `ORDER`). `metric_delta_scenario` calls every `check` right after its built-in checks, and every present option's
  `fixtures` where `player_spell_power` was applied (after the player ratings, before the striker creature).
- Two named points only; an option that must add steps inside a phase or fields to the model adds that point in its
  own ADR, at the place the step order requires.
- `corpse`'s two checks run at the end of the check chain instead of among the built-in ones, and its creature is
  added after the player ratings instead of before: neither changes a valid entry's scenario (the ratings touch only
  the player, and `creatures` is added at the same key position). `generate --class 19`, `--stack` and
  `--class 23` stay byte-identical.
- `test_kinds.py` also runs `metric_delta_options/test_*.py` and checks that every option module names its field,
  parses it, has a test file and does not shadow a `MetricDeltaSpec` field.

## Consequences

- A new `metric_delta` option is one module, one test file and one page, plus a named point when the two do not
  fit.
- The other 60 fields stay in the dataclass; moving one needs its own hook point at the exact place its steps take
  today, or the generated scenarios change. That is residual risk, not a defect: new options no longer add to it.
- An entry for an invalid combination of a built-in field and a module option may now raise a different one of its
  errors first.
