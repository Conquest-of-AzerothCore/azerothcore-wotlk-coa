# 1180. A pick effect refreshes the stats after the skill fixture

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-22
- Builds on: ADR 1163 (`pick_effect`)

## Context

Sweep 20261122-053609, Loa's Blessing 705848 `pick_crit`: the first trial that picked Cunning of Quetz'lun 802215
(aura 290, +3 critical strike chance) read the melee critical strike chance 0 before the cast and 7.99966 after it,
and every later trial read 4.99966 without the blessing. The fixture sets the weapon skills with `Player::SetSkill`
(the `set_skill` steps of `profile.base_steps`), which does not recompute `PLAYER_CRIT_PERCENTAGE`; the field kept the
value computed while the weapon skill was still below the level maximum (clamped to 0, StatSystem.cpp:840 and 848).
The first aura 290 application recomputed every critical strike field (`UpdateAllCritPercentages`) with the fixture
skill, so its trial measured its own +3 plus the skill term. In play a weapon skill gain recomputes the fields
(`Player::UpdateWeaponSkill`, PlayerUpdates.cpp:1138), so this is a fixture fault, not a server fault. The Nature
spell critical strike chance, which has no weapon skill term, read +3 in the same trial.

## Decision

`pick_effect` scenarios set the fixture's weapon skills with `refresh_stats` (the existing `set_skill` option, which
calls `Player::UpdateAllStats`), so the states the first trial reads are current. No other kind changes.

## Consequences

Classes 19 (with and without `--stack`) and 23 generate byte-identical scenarios (no `pick_effect` entry). Class 13
changes one scenario, conformance-witch-doctor-behaviour-705848-pick-effect-blessings (the `set_skill` steps gain
`refresh_stats`).
