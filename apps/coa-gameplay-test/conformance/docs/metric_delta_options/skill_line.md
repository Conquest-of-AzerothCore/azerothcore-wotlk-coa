# Skill line (`metric_delta` `skill_line`, ADR 1030)

`skill_line` is `{"skill": id, "value": n, "maximum": n}` (1 <= value <= maximum <= 450). At the start of the before
phase the caster is given that skill line (`set_skill`), a precondition fixture for an aura that modifies a line the
reference character does not hold: `Player::ModifySkillBonus` ignores a missing line. The after phase keeps it.
Absent, the scenario is unchanged.

Named point: `phase_steps(spec, value, after)`, called with `after` false only for the step.

Witch Doctor: Natural Alchemist 536213 `alchemy_bonus` (Alchemy 171, its `skill_bonus` 0 without the passive and 15
with it).
