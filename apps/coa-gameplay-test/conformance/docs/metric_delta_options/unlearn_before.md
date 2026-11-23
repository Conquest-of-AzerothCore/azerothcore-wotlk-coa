# Unlearn before (`metric_delta` `unlearn_before`)

`unlearn_before` is a non-empty list of distinct spell ids. At the start of the before phase the caster unlearns
them (`unlearn`), for a passive the class starts with (`playercreateinfo_spell_custom`): without it the before
reading already carries the passive and the learn between the phases changes nothing. The after phase learns the
entry's spell as usual. Absent, the scenario is unchanged.

Named point: `phase_steps(spec, value, after)`, called with `after` false only for the steps.

Witch Doctor: Natural Alchemist 536213 `alchemy_bonus` (a class 13 starting spell; Alchemy 171 `skill_bonus` 0
without it and 15 with it).
