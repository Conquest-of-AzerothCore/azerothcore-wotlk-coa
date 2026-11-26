# Unlearn after specialization (`metric_delta` `unlearn_after_specialization`, ADR 1292)

`unlearn_after_specialization` is a non-empty list of distinct spell ids. It requires `specialization` and runs at
`ORDER = 27`, strictly after `specialization` (`ORDER = 26`), emitting `unlearn` steps for each spell before the
`before` measurement.

At level 60, switching to a specialization triggers `SynchronizeAutomaticTalents` and `SynchronizeTaughtAbilities`,
which auto-learn the specialization's level-10 automatic passive and the active ability it teaches before the control
arm is read. `unlearn_before` (`ORDER = 20`) runs before `specialization` and cannot clear them. Unlearning the passive
and its taught spell after the specialization switch leaves the caster in the required specialization with the control
arm reading `0` (`knows_spell`), and the `learn` between phases teaches the spell for `1` in the treatment arm.

Refuses an entry without `specialization` (use `unlearn_before` instead). Absent, the scenario is unchanged.

Named points: `check`, `phase_steps(spec, value, after)` (called with `after` false only for the steps), `fixtures`.

Cultist: Herald of the Depths 92131 `teaches_herald` (spec 40, unlearns `[92131, 520326]`, teaches `520326`),
Dreadnought 680750 `teaches_dreadnought` (spec 96, unlearns `[680750, 567524]`, teaches `567524`).
