# 0728. A proc baseline leaves out its own trigger casts

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

A proc that recasts its own trigger (Smite Evil 803364 through Flames of the Sinned 560207, Witch Hunter 96.0; also
59.0, 62.0 and 284.0) counts its events as `spell_cast_count` of the trigger with `events_exclude_trigger_casts`: the
judge subtracts the completed player casts from the events of the main phase (`player_casts` in `compare.py`). The
`baseline: true` phase, the control arm cast before the passive is learned, read the same cumulative counter without
that subtraction, so every baseline cast counted as an event and the judge alerted with "20 events in 20 baseline
trials without the passive" (c12 Inquisition run 20261115-230308, c12 Boltslinger probe 20261115-224514). Mentor
decision D-187.

## Options

- Subtract the completed baseline casts of the trigger from the baseline events when `exclude_trigger_casts` is set.
- A separate player-cast counter in the baseline phase: the harness has no metric that counts only the casts a
  player submits, and adding one is a harness change.
- Drop the baseline for these entries: leaves 96.0, 59.0, 62.0 and 284.0 without a control arm.

## Decision

The first option. The completed baseline casts are the baseline attempts less the trigger's cast failures of the run.
The harness does not record which phase a failure happened in, so a failure anywhere lowers the subtraction: the
baseline can only read higher, never hide a proc (a false alert, not a false pass). The main phase still subtracts the
raw baseline count from the cumulative events, as before. The alert names the subtraction ("2 events beyond its 20
completed player casts in 20 baseline trials"); the generated rule says "no event beyond their own completed casts".

## Consequences

- Only entries with both `baseline` and `events_exclude_trigger_casts` change; Templar has the exclusion without a
  baseline and Necromancer neither, so Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests (`test_procs.py`, `ExcludedTriggerCastBaselineTest`): baseline events equal to its own casts pass; two
  more alert; without the exclusion the same reading alerts as before; a failed cast lowers the subtraction and
  alerts. The two alerting cases are the seeded mutants of the new check.
- Witch Hunter: the plain Flames of the Sinned entry (96.0) gets `baseline: true`, its control arm.
