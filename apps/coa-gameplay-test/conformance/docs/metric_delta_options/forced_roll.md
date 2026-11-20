# Forced roll (`metric_delta` `forced_roll`, ADR 0588)

`forced_roll` names a talent whose roll the scenario forces: a `SPELLMOD_CHANCE_OF_SUCCESS` +1000% spell modifier
mutant (the `forced_chance` fixture of ADR 0482 and the `cost_gate` `forced_roll` of ADR 0545) is set right after the
base steps and removed at the end, and its removal is read (`spell_mod_mutants` 0). Unlike `forced_chance`, nothing is
read on a creature: the entry's own reading shows whether the forced proc took effect, so a proc whose effect lands on
the caster (a buff, an instant cast) can be judged. The verdict is the metric-delta verdict, and an alert when the
mutant is still active at the end. An entry may not set both `forced_roll` and `forced_chance`.

`forced_roll` may also be `{"talent": ID, "release_after_setup": N}` (ADR 0589): in the treatment phase the mutant is
removed and the talent unlearned right after setup cast N (0-based), so the casts after it cannot roll the talent
again. A release index the entry does not have is refused.

The dict form may also name `"forced_percent": P` (ADR 0752), a whole percent in (0, 10000] that replaces the default
+1000% of the mutant, for a roll that +1000% leaves short of 100% (Witch Hunter Expert Killer 804404: 8% x 11 = 88%,
so `forced_percent` 1200 gives 8% x 13 = 104%, every roll lands). The model then carries the percent; without it the
scenario is unchanged.

Named points: `fixtures` (the mutant and the release steps), `setup_cast_steps` (the release inside a phase) and
`model(spec, value)` (the release label), merged into
the expectation model by `metric_delta_options.option_model`.

Necromancer: Death Commander 300235 (caster and minion haste after a landed proc, claim 6.1) and Bone King 707175
(instant Lichfrost, claim 208.1); Permafrost 704681 (two of three Glacial Impacts treated as frozen after one
proc, claim 167.1, `release_after_setup` 0).
