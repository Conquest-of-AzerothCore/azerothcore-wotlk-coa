# 1113. An enemy can cast before the trigger, and action buttons can be set

- Status: accepted (provisional number, renumbered at merge)
- Date: 2026-11-21
- Builds on: ADR 0582 (metric_delta option modules), ADR 0214 (an enemy player in metric_delta)

## Context

Two Witch Doctor claims needed a state set before the trigger cast that no `metric_delta` field could set:

- Hir'eek's Jinx 803325 "(8 sec vs players)": the Jinx is Beast-only, so the enemy player must already be a Beast (a
  Druid in Cat Form) when it is cast; `enemy_casts` cast after the trigger, so the Jinx was refused first (cycle 8 tool
  note).
- Rite of the Loa 575025 "Simultaneously places each selected Ward, Effigy, and Idol all at once.":
  `SPELL_EFFECT_CAST_BUTTON` casts the spells on action buttons 132 to 135; the harness had `set_action_button`, but no
  option set buttons before a cast (cycle 6 and 8 tool note).

## Decision

- Option module `enemy_casts_before` (a list of spell ids): once, at the start of the before phase and before any
  trigger cast, the enemy player learns and casts each at itself, 500 ms apart (named point `phase_steps`). It needs
  `enemy_player_race`; the state must last through the treatment phase (a shapeshift form is cast once, since a
  second cast would cancel it).
- Option module `action_buttons` (a list of `[button, spell]`, each spell in the entry's `learn`): in the treatment
  phase only, before the trigger cast, each spell's cooldown is reset and it is put on its button; the control phase
  leaves the buttons empty.

## Consequences

- Witch Doctor: `803325 jinx_player_lasts`; `575025 rite_ward`, `rite_effigy` and `rite_idol`.
- New modules only; classes 19 (with and without `--stack`) and 23 generate byte-identical output.
