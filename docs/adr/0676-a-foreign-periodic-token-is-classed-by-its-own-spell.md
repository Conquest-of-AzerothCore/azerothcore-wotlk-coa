# 0676. A foreign periodic token is classed by its own spell

- Status: proposed (provisional number, numbered at merge)
- Date: 2026-11-15
- Builds on: ADR 0039

## Context

`periodic_reason` (values.py) decides whether a token is a total over ticks from the aura and amplitude of the
rank's own effect. A token of another spell is never classed: Feast of Talons 500056
`${($500564d*1000/$500564T1)*(...)}` (500564 aura 3, 6 ticks) and Shadow Trap 680238
`${($681177d*1000/$681177T1)*(...)}` (681177 aura 3, 4 ticks) were judged against one `spell_effect_value` read, one
tick (final04: 302 against 1817.7, 211 against 848.52), false alerts.

## Options

- Leave them alerting: a known false alert in every count.
- Class the token by its own spell's effect, as an own token is classed by the rank's.

## Decision

For a foreign effect token, `periodic_reason` reads the token spell's aura and amplitude, and `period_reading` scales
that spell's duration and period. A `total` over ticks goes to `periodic_totals` under its foreign label with
`effect_spell`; a `tick` or `mixed` foreign token keeps its `effect_value` read.

## Consequences

- Tests: the 500056 and 680238 labels leave the value scenario for `periodic_totals`; Templar 500694's per-tick
  foreign token keeps its read.
- The two Witch Hunter labels become `unmodelled` periodic totals (500056 is a passive never cast; 680238's own
  effects deal no damage): no false alert, not yet judged. A per-tick judge of a foreign total is a later design.
- Templar and Necromancer generations stay byte-identical.
