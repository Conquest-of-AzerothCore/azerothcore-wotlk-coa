# 1101. A ratio to metric can divide the after-phase increments of two running totals

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 1030 (ratio_to_metric)

## Context

`ratio_to_metric` divides each judged reading by a second read of the same unit. Event totals such as
`spell_damage_total` run over the whole scenario, so when the trigger is cast in both phases the after base holds both
phases' damage and the ratio is not the stated share (Voodoo Strings 705910, Master of Concoctions 801690, the
Shadowhunter heal of Malefic Arrow 707854).

## Decision

`ratio_to_metric` takes `increments` (boolean, default false). With it the after reading is (after - before) divided
by (after base - before base); the before reading stays the plain ratio. A zero or missing increment leaves the
reading missing.

## Consequences

Opt-in; existing entries and classes 19 and 23 generate unchanged.
