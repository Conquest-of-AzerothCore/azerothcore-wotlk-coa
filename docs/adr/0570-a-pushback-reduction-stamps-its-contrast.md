# 0570. A pushback reduction stamps its contrast

- Status: accepted
- Date: 2026-11-13
- Amends: ADR 0543 (pushback reduction), in the spirit of ADR 0553 (F2's own-cast contrast for `metric_delta`)

## Context

The merged pair 20261113-105514 / -111950 classed 360.3, Icebound Champion 807813 "reduces the pushback suffered from
damaging attacks while casting by $807812s1%", as data although the `pushback_reduction` label read ok in both runs.
The kind reads the caster's `casting` state, a state metric; coverage counts a state read as behaviour only in a
`learned` contrast (`coverage.promised_state`), and the kind's model carried no `contrast`, so the verdict detail had
none. ADR 0553 (F2's branch) stamps `own_cast` for a `metric_delta` state read after the spell's own cast and lets
`promised_state` accept it; the integration note asks the same stamp of this kind.

## Decision

- The `pushback_reduction` model stamps `contrast`: `learned` with `reducer_learn` (the reducer is learned between
  the phases), `own_cast` when `reducer_spell` is the entry's own spell (a real cast of the claimed spell),
  `condition` otherwise.
- `coverage.promised_state` accepts `learned` and `own_cast` for `behaviour_metric_delta`, the same line as ADR 0553,
  and `OWN_CAST_CONTRAST = 'own_cast'` is defined in `behaviours.py` as there, so the integrator's union of the two
  branches is one definition.

## Consequences

- 360.3 (807813, own cast) and 240.0 (802988, learned) audit as behaviour where the clause names casting.
- Tests: `PushbackReductionTests` (test_behaviours.py), seeded with a judged pushback run; the condition contrast,
  a foreign reducer and a clause without the promise word are the mutants. Templar has no pushback entry, so its
  generation is unchanged.
