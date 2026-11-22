# Specialization (`metric_delta` `specialization`, ADR 1102)

`specialization` is a specialization id. At the start of the before phase the caster switches to it (the harness
`specialization` step), a precondition fixture for an ability a talent teaches only in that specialization
(`SynchronizeTaughtAbilities`). A `money` step of 1,000,000 copper comes first, because the switch charges the cost
of unlearning the active specialization's entries and the reference character has no money. Absent, the scenario is
unchanged.

Named point: `phase_steps(spec, value, after)`, called with `after` false only for the step.

Witch Doctor: Mixologist 561069 `fish_taught` (specialization 6; Ingredient: Fish Oil 801662 taught by the learn).
