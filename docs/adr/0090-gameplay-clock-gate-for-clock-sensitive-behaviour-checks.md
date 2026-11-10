# 0090. Gameplay-clock gate for clock-sensitive behaviour checks

## Context

Testament of Fortitude 500678's `dispel_removal` entry (`classes/templar.json`) sets
`"gameplay_clock": "real"`, documenting that its periodic trigger (`500690`, amplitude 1000 ms) never fires
under the harness's default simulated/accelerated clock at any wait length up to 14000 ms, confirmed via
temporary, reverted `LOG_ERROR` tracing (`Spell::DoAllEffectOnTarget`/`Spell::EffectDispel` never reached for
spell 500690 under the simulated clock, over the aura's whole lifetime), while a real-clock run reliably
reproduces it. This is the harness's simulated-clock handling of `SPELL_AURA_PERIODIC_TRIGGER_SPELL_WITH_VALUE`
(227), not a Templar server defect.

Conformance scenarios are always exploratory files (`conformance.py generate` writes them outside the catalog),
so `batch.py`'s real-pace rerun queue (`--gameplay-real-pace-rerun`), which only retries non-exploratory catalog
cases, never applies to them; the only way to exercise this scenario under real wall time is the whole-run
`--gameplay-clock real` flag. Before this ADR, `"gameplay_clock": "real"` was read nowhere in
`apps/coa-gameplay-test/conformance/*.py` (confirmed by `grep -rn "gameplay_clock"` over that tree): it
documented an operational requirement for a human to remember, with no effect on `compare.py`'s judging. A
future default (`--gameplay-clock simulated`, the default) run of this scenario would read the fixture debuff
still present after the wait and report `alert`, which an unaware reader could mistake for a regression of an
already-proven `ok` clause.

## Decision

- `Run` (`compare.py`) gains a `clock` field (`'real'` or `'simulated'`), read from each case's own
  `summary.json`: the presence of a `simulation` key (written only when `batch.simulated`, i.e. the whole
  batch ran on the simulated clock) distinguishes the two, exactly as `batch.py`'s own `case_record`/`summary`
  writers already encode it. `None` when `summary.json` is absent or unreadable, so an unrelated gap in test
  fixtures never silently gates a check that was never meant to be gated.
- `Expectation.model` may carry a `gameplay_clock` key (`'real'` or `'simulated'`); `dispel_removal_scenario`
  (`behaviours.py`) threads the class-file entry's own `gameplay_clock` field into every `Expectation` it
  builds, via a new `DispelRemovalSpec.gameplay_clock` field, defaulting to `None` so every existing entry
  without the key is unaffected.
- `judge_expectation` (`compare.py`) gates on it generically, before any check-specific judging: when
  `expectation.model['gameplay_clock']` is set and the run's own `clock` is known and does not match, the
  verdict is `unmeasured` (an existing status, not a new one), not `alert` and not a silent `ok`. A `run.clock`
  of `None` (unknown) never gates, so this only fires when the mismatch is actually established.
- This is deliberately class-agnostic and not specific to `dispel_removal`: any future `behaviours` entry of
  any class that sets `gameplay_clock` in its model gets the same protection, with no new tool code.

## Consequences

- A default (simulated-clock) `conformance.py compare` run of Testament of Fortitude's clause now reports
  `unmeasured` ("recorded under the simulated clock; this scenario requires --gameplay-clock real..."),
  not `alert`, so it is never mistaken for a regression of the `ok` verdict a real-clock run established.
- A `--gameplay-clock real` run still judges the clause normally (`ok`/`alert`) through the unchanged
  `behaviour_metric_delta_verdict` path; the real-clock requirement is the only thing gated, not the clause's
  own measurement.
- Rebuke 525051's three `dispel_removal` clauses (no `gameplay_clock` set) are unaffected: `model.get(...)`
  returns `None`, the gate never triggers, and they judge exactly as before.
