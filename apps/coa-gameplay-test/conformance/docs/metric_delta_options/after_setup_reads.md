# After setup reads (`metric_delta` `after_setup_reads`, ADR 1227)

`after_setup_reads` is a non-empty list of `{"spell": id, "expected": 0 or 1}`. In every phase that makes the
entry's `setup_casts`, right after the last setup cast (and its `setup_wait_ms`), before the triggering cast, the
scenario reads `aura_stacks` of each spell on the caster, labelled `<spell> after_setup_reads <aura> before|after`.
A read that does not match `expected` (0 = absent, 1 = present) makes the run `unmeasured`; so does a missing
after-phase read. A before-phase read is judged when the before phase made the setup casts (it has none with
`setup_only_after`, or with `cast_in_before` false and no `setup_in_before`). A match leaves the plain verdict. The
read is a precondition check: it never makes a verdict `ok` or `alert` and adds no counted label.

Needs `setup_casts` and no `attack_swings` (that flow casts its setup through another path).

Named points: `setup_cast_steps` (at the last index), `fixtures` (contract sentence), `model`, `verdict`.

Sun Cleric: Dawn 807440 expected 1 on the entries whose setup casts Dawn 804584 and whose claim needs Dawn up at the
judged cast.
