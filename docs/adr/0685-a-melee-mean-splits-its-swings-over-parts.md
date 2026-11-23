# 0685. A melee mean splits its swings over parts

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0139, ADR 0195

## Context

`hits.melee_scenario` reads the plain main-hand hits of the reference weapon in one scenario. With the Witch Hunter
weapon sets (ADR 0681) the reference weapon is the Houndmaster main hand 2027 (17.25 to 28.75, 2300 ms), whose
spread raises the swings the mean needs: the scenario would wait 632,900 ms, above the 10-minute budget the tool keeps
for splitting casts over parts (ADR 0139), so `generate` wrote `melee melee_mean` as unmodelled (counted pair
20261115-100256 / -100722, mentor D-55). Hit entries already split their casts over parts that `compare.judge_hit`
pools under one label; the melee scenario had no parts.

## Options

- The accelerated one-hour cap: ADR 0139 keeps the 10-minute budget for splitting, so a real-pace reference run stays
  possible.
- Fewer swings: lowers the mean's precision below the hit rule.
- Parts, as for hit entries.

## Decision

- A class file opts in with `"melee_parts": true`. `hits.melee_parts(class_file, swings)` returns one
  `melee_scenario` when the scheduled swings fit the budget (`MAX_SCENARIO_MS - TIMEOUT_MARGIN_MS - SETTLE_MS`) or the
  class file does not opt in, unchanged; otherwise it splits the scheduled swings evenly
  over the fewest parts that fit, each named `part <n> of <parts>`, with `part`, `parts` and `part_swings` in the
  model and the contract, under the one `melee melee_mean` label. `generate` keys them `<melee key>-part-<n>`.
- `compare.judge_hit` pools them as it pools hit parts (unchanged).

## Consequences

- Witch Hunter: the melee mean runs as 2 parts of 380,100 ms timeout each.
- Templar (19) and Necromancer (23) do not opt in and generate byte-identical scenarios. Necromancer's melee mean is
  longer than the budget too (3 parts when split) and stays unmodelled until its own class decides.
- Tests in `test_hits.py`: a melee scenario inside the budget is the single scenario, and the Witch Hunter melee mean
  splits into parts under one label (and, without the opt-in, is still refused) whose swings cover the scheduled
  swings, each part validated and inside the cap. The split adds no check, so it has no mutant.
