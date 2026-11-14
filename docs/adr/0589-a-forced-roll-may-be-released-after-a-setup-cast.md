# 0589. A forced roll may be released after a setup cast

- Status: accepted
- Date: 2026-11-13
- Builds on: ADR 0582, ADR 0588

## Context

Permafrost 704681 "your next 2 spells" (claim 167.1, gap T1) needs one landed proc followed by casts that consume
its charges. Under the `forced_roll` mutant of ADR 0588 every Necromancer spell rolls 704681 again, so each Glacial
Impact would refresh the charges and the third impact could never be refused.

## Options

1. A new `MetricDeltaSpec` field for steps between setup casts, judged in `behaviours.py`.
2. `forced_roll` takes `{talent, release_after_setup}`; a fourth named point of the option modules (ADR 0582),
   `option_setup_cast_steps(spec, index, after)`, adds steps after a setup cast.

## Decision

Option 2. In the treatment phase, right after setup cast `release_after_setup` (0-based), `forced_roll` removes the
mutant and unlearns the talent, so the later casts cannot roll it. The control phase is unchanged. A release index
the entry does not have, or another key, is refused. The plain talent value keeps the ADR 0588 behaviour.
`behaviours.py` gains only the call to the hook: its setup casts are built inside `metric_delta_scenario`, which no
option point reached.

## Consequences

- Permafrost 704681 `next_two`: after one Command: Undead 504868 with the roll forced, two of three Glacial Impacts
  at an unfrozen dummy go out (0 in the no-talent control).
- Parasites 560730 `parasites_lasts` stays withdrawn: its 5% chance times 11 under the mutant is 55%, not certain.
