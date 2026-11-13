# Forced roll (`metric_delta` `forced_roll`, ADR 0588)

`forced_roll` names a talent whose roll the scenario forces: a `SPELLMOD_CHANCE_OF_SUCCESS` +1000% spell modifier
mutant (the `forced_chance` fixture of ADR 0482 and the `cost_gate` `forced_roll` of ADR 0545) is set right after the
base steps and removed at the end, and its removal is read (`spell_mod_mutants` 0). Unlike `forced_chance`, nothing is
read on a creature: the entry's own reading shows whether the forced proc took effect, so a proc whose effect lands on
the caster (a buff, an instant cast) can be judged. The verdict is the metric-delta verdict, and an alert when the
mutant is still active at the end. An entry may not set both `forced_roll` and `forced_chance`.

Named points: `fixtures` (the mutant and the release steps) and `model(spec, value)` (the release label), merged into
the expectation model by `metric_delta_options.option_model`.

Necromancer: Death Commander 300235 (caster and minion haste after a landed proc, claim 6.1) and Bone King 707175
(instant Lichfrost, claim 208.1).
