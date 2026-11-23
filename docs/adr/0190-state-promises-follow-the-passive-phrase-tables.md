# 0190. State promises follow the passive phrase tables

- Status: accepted
- Date: 2026-11-11

## Context

A state read (`passive_delta`, a learned `behaviour_metric_delta`, `behaviour_party_stat_ratio`) counts as behaviour
only when the clause names the stat it reads (`coverage.STATE_PROMISES`). Two Templar claims read the right stat in a
learned contrast and still counted as data:

- Sturdy 681537, "Increases your maximum health and Energy by $s1%". The ledger splits it into "Increases your
  maximum health ... by $s1%" and "and Energy by $s1%". `max_power` read 100 to 110 exactly, but its promise asked for
  "maximum energy", which the second half no longer carries.
- Calm Combatant 705281, "and your Armor penetration by $s2% of your Intellect". `combat_rating` 24 read 0 to 16
  exactly (50% of Intellect 32), but its promise asked for "rating".

The passive generator already names these quantities differently: `passives.POWER_NAMES` gives the bare power name
("Energy") as the phrase of a `max_power` plan, and `passives.RATING_NAMES` gives "armor penetration" for rating 24.
The promise table disagreed with the phrases the plans were built from.

## Considered options

1. Rewrite the two ledger rows with the words the split dropped. Rejected: the ledger quotes the tooltip, and the
   same gap would return on the next split clause or rating.
2. Widen the two promises by hand. Rejected: a third wording table to keep in step.
3. Build the `max_power` and `combat_rating` promises from the passive phrase tables. Chosen.

## Decision

- `STATE_PROMISES['max_power']` is the alternation of `POWER_NAMES` values.
- `STATE_PROMISES['combat_rating']` is "rating" or any `RATING_NAMES` value.
- Every other promise is unchanged, and a stat read for a clause that does not name it stays data.

## Consequences

- Claims 157 (Sturdy, "and Energy by $s1%") and 188 (Calm Combatant, "Armor penetration") become behaviour proven
  on their passive scenarios' counted pair. No other Templar claim moves.
- A `max_power` read no longer needs the word "maximum"; a clause that names only another stat still gives data.
- No scenario changes: the class's 1,418 scenarios and 40 stack scenarios regenerate byte-identical.
- Tests: `test_coverage.EvidenceStatusTest.test_a_split_clause_names_the_power_without_its_maximum`,
  `test_armor_penetration_promises_its_combat_rating`, `test_state_promises_name_every_phrase_of_the_passive_tables`.
