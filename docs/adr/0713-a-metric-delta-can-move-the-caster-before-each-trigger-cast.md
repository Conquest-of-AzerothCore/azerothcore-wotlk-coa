# 0713. A metric delta can move the caster before each trigger cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Strategist 681156 (Witch Hunter): "Your Hunt now regenerates 5% maximum mana". Hunt 802006 is a charge (Effect[0] 96)
with SpellRange 54 (5 to 30 yd). A metric_delta entry casting Hunt failed with SPELL_FAILED_TOO_CLOSE (c11-inq,
c11-bk): the control cast carries the caster to the dummy, so the treatment cast starts inside the minimum range.
`cast_in_before: false` drops the control cast, and a strike's `dx` brings a striker hit. Mentor decision D-160 (c12
tool batch item 3).

## Options

- A `metric_delta` option module `relocate_before_trigger` that inserts a harness `relocate` (relative, along x)
  before each trigger cast.
- An absolute placement step in the harness: C++ for what a relative move already gives.

## Decision

The option module `metric_delta_options/relocate_before_trigger.py`: `{"dx": yards}`, a `relocate` step right before
each cast of the trigger spell by the caster, named in the contract and the model. It adds no check.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no entry states the option).
- Witch Hunter: `681156 behaviour_metric_delta hunt_mana` (Hunt branch of the clause).
