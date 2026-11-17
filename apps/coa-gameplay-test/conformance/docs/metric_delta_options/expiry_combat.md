# Expiry combat (`metric_delta` `expiry_combat`)

`expiry_combat: {"late_wait_ms": ms}` is for an entry with `expiry_wait_ms`, `after_expiry_expected` and
`expiry_below_after`. The scenario reads the caster's `combat` right before the expired reading, waits `late_wait_ms`,
then reads `combat` and the metric again. After the plain verdict is `ok`, the option judges a decay "while out of
combat": both `combat` reads must be 0 (a caster still in combat is `unmeasured`: the decay is not out of combat), and
the late reading must be below the expired one and at or above `after_expiry_expected` (otherwise `alert`). Absent,
nothing is read and the verdict is unchanged.

Named point: `verdict(verdict, run, value)`, as `before_aura_absent`; `fixtures` adds the reads.

Witch Hunter: Unbroken 707407 `decays_out_of_combat` (attack power after one hit, read twice out of combat; claim 297.1).
