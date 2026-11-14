# 0444. A no-stack clause is not promised by its words alone

- Status: accepted; supersedes the no-stack part of ADR 0440
- Date: 2026-11-13

## Context

ADR 0440 let a learned-contrast `behaviour_metric_delta` state read promise any clause carrying "does not stack". The
B4 side c review (I-8, C-1) showed the gap: the Apothecary's Cauldron 560537 entry learned Dark Prophecy 800517, which
is not passive (Attributes 0x40000), so the second effect never applied and the equal readings could not fail. The
mentor's rule for a no-stack clause is a relation (equal consumed values after one and after two or more real
applications), and the metric_delta verdict carries no field from which coverage could check it.

## Decision

`coverage.promised_state` no longer adds the no-stack words for `behaviour_metric_delta`; only ADR 0424's
`behaviour_group_stack_cap` rule promises a no-stack clause. The "spell haste" promise of ADR 0440 stays.

## Consequences

- 560537's "Does not stack" clause is read with a real Dark Prophecy cast (its aura read present, Dark Prophecy alone
  read at 1/1.02), and stays open until a stack-cap judge for an inverse-relation state read exists.
- Tests: `SpellHasteAndNoStackPromiseTest` (test_coverage.py): a learned no-stack contrast reads data, and a seeded
  mutant that promises the words is caught.
