# After start reads (`metric_delta` `after_start_reads`, ADR 1039)

`after_start_reads` is a non-empty list of `{"spell": id, "expected": 0 or 1}`. In the after phase only, right after
the `after_auras` and `phase_auras` steps (so after a `set_aura` with 0 stacks removed the aura), the scenario reads
`aura_stacks` of each spell on the caster. A read that does not match `expected` (0 = absent, 1 = present), or a
missing read, makes the run `unmeasured`; a match leaves the plain verdict. The read is a diagnostic precondition
check: it never makes a verdict `ok` or `alert` and adds no counted label.

Named points: `phase_steps` (after phase only), `model`, `verdict`.

Sun Cleric: Dawn 807440 expected 0 on the entries that remove it with `after_auras` (92136, 561329, 561328).
