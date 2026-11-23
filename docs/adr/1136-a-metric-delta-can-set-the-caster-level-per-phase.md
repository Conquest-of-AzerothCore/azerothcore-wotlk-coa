# 1136. A metric-delta can set the caster level per phase

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582

## Context

Arcane Brew 801689 "Spell power scales with caster level." The amount is BasePoints 29 + 1 plus 1.5 per level above
SpellLevel 31 (58.5 at level 50, 73.5 at level 60); a proof needs the same cast at two caster levels (tool note
T-c9-B16-7).

## Decision

The option `phase_caster_level` `[before, after]` sets the caster's level (harness `set_level`, `Player::GiveLevel`)
at the start of each phase. A lower level is a scenario fixture for this claim only; the class level stays 60.

## Consequences

Opt-in only; generated scenarios of classes 19 (with and without `--stack`) and 23 are byte-identical. Class 13 gains
801689 `level_scaling`. The level policy (a lower level needs a ruling) is listed for the owner.
