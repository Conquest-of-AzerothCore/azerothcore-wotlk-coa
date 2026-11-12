# 0258. A stat gain carries its learned or condition contrast

- Status: accepted
- Date: 2026-11-12

## Context

ADR 0213 judges a `stat_gain` entry under the `behaviour_metric_delta` check name. Clause coverage counts a state read
(`armor`, `spell_power`, `attack_power`) of that check as behaviour only when the verdict detail carries the `learned`
contrast and the clause names the stat (ADR 0120, `coverage.promised_state`). The `metric_delta` model stamps that
contrast; the `stat_gain` model did not. So the counted pairs of Improved Benediction 705287 (claim 196, the grouped
ally's armor gains 0 without the talent and Agility + Stamina with it) and Libram of Fervor 805423 (claims 411 and 412,
Holy spell power and attack power read before and after a real cast with the Libram aura cleared first) stayed data.

## Options

1. Keep the claims at data. That ignores the arms that the entries already contain.
2. Stamp `learned` on every `stat_gain`. That would also count an entry whose arms all know the spell, where the
   gain shows the cast but not the claimed spell.
3. Stamp the contrast that the arms actually make.

## Decision

Option 3. `stat_gain_contrast` returns `learned` when one of two conditions holds:
- the cast spell is the entry's spell and its aura is in `clear_auras`, so the reading before each cast is the
  control without the spell;
- the first arm does not learn the entry's spell and a later arm does.

Every other entry is `condition`. The model's `contrast` goes into the verdict detail through `compare.observed`, as
it does for `metric_delta`.

## Consequences

- 705287 `armor` (without / with arms) and 805423 `spell_power` and `attack_power` (their own cast, aura cleared)
  carry `learned`. Regenerated scenario files are byte-identical (1838 of 1838). The manifest changes only in these
  three models.
- Seeded tests: both entries count as behaviour. Two mutants stay data: arms that all learn 705287, and a Libram
  entry that keeps its aura before the cast.
- Verdicts judged before this change carry no contrast, so the scenarios were run again to stamp it.
