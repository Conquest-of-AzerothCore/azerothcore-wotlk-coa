# 0993. A metric delta can move the caster during the wait after the trigger cast

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-16

## Context

Twilight Frenzy 805751 (Witch Hunter): "Can dodge and parry and move while active." The move half had no label:
`moving_before_trigger` sets a movement flag with `set_moving`, which only sets the flag and never runs the movement
interrupts, and `relocate_before_trigger` moves the caster before the cast. A channel is interrupted by movement
through `Unit::UpdatePosition` and `RemoveAurasWithInterruptFlags` (ChannelInterruptFlags with
AURA_INTERRUPT_FLAG_MOVE), so only a position update during the channel can prove or refute the claim (part 380.2,
mentor D-356).

## Options

- A `metric_delta` option module that inserts alternating harness `relocate` steps after the trigger cast.
- A harness change (C++) that applies movement interrupts from `set_moving`: a shared harness edit for what an
  existing step already gives.

## Decision

`metric_delta_options/relocate_during_wait.py`: `{"every_ms", "count", "dy"}`, an even count of `relocate` moves of
`dy` yd along y and back, `every_ms` apart, through the named point `after_trigger_steps`. Opt-in and inert for
entries that do not set it (standing approval O-29 / D-293 point 3).

## Consequences

- Other classes regenerate byte-identical (no entry states the option).
- Witch Hunter: Twilight Frenzy 805751 and its Witchbane 574320 control arms.
