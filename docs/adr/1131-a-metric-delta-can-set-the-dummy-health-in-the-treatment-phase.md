# 1131. A metric-delta can set the dummy's health in the treatment phase

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582

## Context

Shadowflare 501146 "Killing an enemy with this spell grants you a Spirit" needs a hit that kills the dummy. The dummy
has 50,000,000 health and `set_health_pct` rounds to at least 1% of it; the harness creature `set_health` was not
reachable from a metric_delta entry (tool note T-b13-4).

## Decision

The option `after_target_health` (a positive health below the dummy's) sets the dummy's health with the creature
`set_health` at the start of the treatment phase; the control phase casts at full health.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13 gains
501146 `kill_spirit`.
