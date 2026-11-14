# 0653. A metric delta control can require an aura absent

- Status: accepted
- Date: 2026-11-14

## Context

A behaviour `metric_delta` reads its control before the learn. On Ghoul Mastery 503740 `snare_control` a fixture can
put a slow on the read creature in the control phase, and the plain judge then reads a slowed control as a failed
claim (cycle 14 pair, run 20261114-021607: 0.57143 before the learn instead of 1.14286). The aura listing read (ADR
0652) named the aura in a diagnostic run (20261114-031546): Dazed 1604 cast by the striker fixture.

## Options

- Remove the aura before the reading: it hides the state instead of naming it.
- Change the striker fixture: shared by other strike entries and outside the claim's scope.
- Read the aura before the reading and judge only a control that does not hold it.

## Decision

The `metric_delta` option `before_aura_absent` (`aura`, `entry`, `source`) reads `owned_creature_aura_max_duration_ms`
of the aura on the owned creature right before the before reading. A run that holds the aura, or has no read, is
`unmeasured`; otherwise the plain verdict stands.

## Consequences

- Test: `BeforeAuraAbsentTests` (metric_delta_options/test_before_aura_absent.py).
- Only entries that set the option change; the Templar scenarios are unchanged.
