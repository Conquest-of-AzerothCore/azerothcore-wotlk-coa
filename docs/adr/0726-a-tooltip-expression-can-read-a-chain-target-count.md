# 0726. A tooltip expression can read a chain target count

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Witch Hunter claim 313.0 (Smite Evil 802004: "... to them and ${$x1-1} nearby enemies.") left `${$x1-1}` unreadable:
the tooltip reader knew no `x` variable, so the stated count had no expected value and no route. In the client's
tooltip grammar `$xN` is the chain target count of effect N (`EffectChainTarget[N-1]`), the number of targets a chain
effect strikes. Mentor decision D-185 (c13 tool batch item 5, design G2a in the c12 gap designs), with a stop if a
finished class's digests move.

## Options

- Read `$xN` / `$<id>xN` inside `${...}` as `EffectChainTarget[N-1]` of the named or described spell, like `$aN`.
- Leave it unreadable and state the count by hand in a behaviour entry: the expected value would then not come from
  the tooltip reader.

## Decision

The first option, inside expressions only (the form the claim uses). The value has no `effect_index`, so it gets no
no-combat read of its own (`unmeasurable: flat token without a no-combat metric`); the count is measured by a
`fixed_count` entry.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (`snapshots.py check`): neither has `$xN` in an expression.
- Seeded test: `${$x1-1}` and `${$x2}` read 5 and 3 from `EffectChainTarget` 6 and 3, nothing unreadable.
- Witch Hunter: the Smite Evil value and hit scenarios lose their unreadable `${$x1-1}` labels, and
  `802004 chain_cap behaviour_fixed_count` measures the 5 nearby enemies (`EffectChainTarget[0]` 6 of 803364).
