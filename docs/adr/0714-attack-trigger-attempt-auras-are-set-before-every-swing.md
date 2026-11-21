# 0714. An attack trigger's attempt auras are set before every swing

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15

## Context

Flames of Sin 92094 (Witch Hunter): "causing your auto attacks to deal an additional 40% of the damage dealt as Fire
damage". The Fire comes from the aura 803422, whose DBC duration is 100 ms (DurationIndex 407); a fixture set once
before the swing block ends long before the first swing interval passes (c11-inq stop). `attempt_auras` was refused on
anything but a cast trigger. Mentor decision D-160 (c12 tool batch item 4).

## Options

- Keep the one swing block and refresh the auras on a timer: a 100 ms aura needs a refresh every world tick or two, and
  a refresh at a fixed period does not line up with the swings.
- One attack per attempt: set the auras, start attacking, stop 50 ms later, wait the rest of the interval.

## Decision

The second option, in `triggers.swing_steps`, used by the attack branches of the trigger count and magnitude ratio
scenarios when `attempt_auras` is set. A ready main hand swings inside the 50 ms window (world ticks are 25 ms or less
on the simulated clock); `Unit::Attack` delays a ready off hand by half a swing at each attack start, so only the main
hand swings, matching the main-hand trial and trigger reads. The rules name the fixtures.

## Consequences

- Templar 19 and Necromancer 23 regenerate byte-identical (no attack trigger states `attempt_auras`).
- Witch Hunter: `92094 trigger_magnitude_ratio` (803422, crit and partial resist removal set before every swing).
