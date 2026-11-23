# 0023. Spirit Out Of The Bottle reaches three additional allies

- Status: accepted
- Date: 2026-11-21

## Context

Spirit Out Of The Bottle 301175: channeling Mojo Beam lets Spirit in a Bottle "affect ${$m2-1} additional allies near
the primary target"; 301175 Effect[1] BasePoints 3 + 1 = 4, so 3. The script stopped at a literal 2: the cycle 11
sweep 20261121-231523 read 2 additional allies healed (`301175 bottle_allies`, expected 3).

## Decision

- The cap reads `Amount(OutOfBottle, EFFECT_1) - 1`, the value the tooltip shows.

## Consequences

- Regression: the class entry `301175 bottle_allies`.
