# 0690. A metric delta can set an aura before the gate learn only

- Status: accepted
- Date: 2026-11-15

## Context

A `metric_delta` phase aura (`phase_auras`, `after_auras`) is set again in the treatment phase, after the gate learn.
The harness `set_aura` step calls `Aura::SetStackAmount`, which recalculates every effect amount with the caster's
current spell modifiers. An entry therefore cannot read an aura as it was applied before the gate was known. Night
King 707067 needs that read: its bonus is a SPELLMOD_EFFECT1 modifier on Shadow Brand 680517, fixed in the Brand's
amount when the Brand is applied (ADR 0002 of the Witch Hunter folder).

## Options

- A new `MetricDeltaSpec` field in the shared tool core.
- A `metric_delta` option module (ADR 0582) that adds steps to the control phase only.

## Decision

The option `before_auras`, a non-empty list of `[spell, stacks, on, by]` in the form of `phase_auras`, sets each aura
in the control phase only, through the named point `phase_steps`. It needs the default gate timing, no
`setup_only_after` and no attack swings, and an aura of the list may not also be a phase or after aura.

## Consequences

- Test: `BeforeAurasTests` (metric_delta_options/test_before_auras.py); page
  `docs/metric_delta_options/before_auras.md`.
- Only entries that set the option change; the finished classes' scenarios are unchanged.
- Number provisional: shared ADRs are numbered at merge.
