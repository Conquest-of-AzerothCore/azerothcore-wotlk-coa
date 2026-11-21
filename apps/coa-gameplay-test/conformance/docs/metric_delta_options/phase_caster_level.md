# Phase caster level (`metric_delta` `phase_caster_level`, ADR 1136)

`phase_caster_level` is `[before level, after level]`, two different levels from 1 to 80. At the start of each phase
the caster's level is set (the harness `set_level`, `Player::GiveLevel`), so the control cast and the treatment cast
differ only by the caster level. It needs both phases cast. Absent, the scenario is unchanged. A level other than the
class level is a fixture of the scenario, not the class's reference character; the entry states why it needs it.

Named points: `phase_steps` (the level steps) and `model`.

Witch Doctor: Arcane Brew 801689 `level_scaling` (the spell power gain read at level 50 and 60, 58.5 against 73.5).
