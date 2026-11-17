# 0725. A metric delta can judge the sum of the last hit shares

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 178.0 ("stacking $524669u times.", Blade of the Misbegotten 680530) has no stack count to read: the
server keeps 524669 at StackAmount 1 (`AscensionWitchHunterCompletion.cpp:254-258`) and models the three stacks as a
three-slot ring of 15% Dawn Blade damage shares, recasting 524669 with the sum of the ring as its base points
(`AscensionWitchHunterEvents.cpp:343-354`). The expected amount depends on the damage of each hit, so no fixed
`expected` can state it; the c10-fix author dropped the StackAmount label and reported the gap. Mentor decision D-185
(c13 tool batch item 4, design G5 in the c12 gap designs).

## Options

- A `metric_delta` option `ring_sum {spell, share_pct, slots}` that reads the hit damage around each treatment cast
  and judges the increase against the sum of the last `slots` truncated shares.
- A new kind: it would repeat the phases, fixtures and contrast of `metric_delta`.
- An owner card for the stack count: the server's choice is documented in code, so the behaviour can be measured.

## Decision

The option. The judge is exact (integer shares, one integer sum), needs more casts than slots, and refuses to judge
(unmeasured) when a cast dealt nothing or the oldest share is 0, since the sum of every hit would then match too. An
increase equal to the sum of every hit alerts.

## Consequences

- Absent by default: Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`).
- Seeded tests: the reads frame each of four casts; the last three shares pass; the sum of four (the mutant that
  forgets the ring) and an off-by-one alert; a zero hit or a zero oldest share is unmeasured; too few casts or a
  malformed ring is refused.
- Witch Hunter: `680530 behaviour_metric_delta ring_sum` (four Dawn Blades 802024, aura amount of 524669).
- The metric is `aura_amount`, a readback: the audit counts the label as data unless the mentor rules otherwise.
