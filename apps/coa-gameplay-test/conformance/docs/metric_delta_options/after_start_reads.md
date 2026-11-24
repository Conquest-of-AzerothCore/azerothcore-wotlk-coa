# After start reads (`metric_delta` `after_start_reads`, ADR 1208)

`after_start_reads` is a non-empty list of `{"spell": id, "expected": 0 or 1}`. In the after phase only, right after
the `after_auras` and `phase_auras` steps (so after a `set_aura` with 0 stacks removed the aura), the scenario reads
`aura_stacks` of each spell on the caster. A read that does not match `expected` (0 = absent, 1 = present), or a
missing read, makes the run `unmeasured`; a match leaves the plain verdict. The read is a diagnostic precondition
check: it never makes a verdict `ok` or `alert` and adds no counted label.

A read may name an `actor` (ADR 1228): a unit of the scenario, the caster or an ally of its `ally_arm`. The read is
then `aura_stacks` on that unit and its label ends with ` <actor>`; without `actor` the read, label and model are the
caster's as before.

Named points: `check` (the actor is a unit of the scenario), `phase_steps` (after phase only), `model`, `verdict`.

Sun Cleric: Dawn 807440 expected 0 on the entries that remove it with `after_auras` (92136, 561329, 561328).
Holy Form 805301: The Redeemer 301005 expected 0 on `ally` and `ally2` (`extra_heal_redeemer` and its controls).
