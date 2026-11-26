# Before trigger reads (`metric_delta` `before_trigger_reads`, ADR 1233, provisional)

`before_trigger_reads` is a non-empty list of `{"spell": id, "expected": 0 or 1, "actor": "caster" or "dummy"}`. Right
after the entry's `phase_auras` and `after_auras` are set, with no wait before the trigger cast, the scenario reads
`aura_stacks` of each spell on the named unit, labelled `<spell> before_trigger_reads <actor> <aura> before|after`. The
after phase is always read; the before phase only when it casts (`cast_in_before`, not `trigger_only_after`, not
`setup_only_after`). A read that does not match `expected` (0 = absent, 1 = present), or a missing read, makes the run
`unmeasured`; a match leaves the plain verdict. The read is a precondition check: it never makes a verdict `ok` or `alert`
and adds no counted label. A spell names one unit once.

Named points: `phase_steps`, `fixtures` (contract sentence), `model`, `verdict`.

Field names match the rc3 `after_start_reads` (`spell`, `expected`, `actor`); `actor` is required here.

Sun Cleric: Divine Shield 642 on the dummy, expected 1 on the Rapture 807372 entries `immune_all` and `immune_all_control`,
expected 0 on `immune_all_control_open` (no shield).
