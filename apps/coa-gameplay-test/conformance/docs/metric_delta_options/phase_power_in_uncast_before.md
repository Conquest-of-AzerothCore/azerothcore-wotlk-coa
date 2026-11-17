# Phase power in an uncast before phase (`metric_delta` `phase_power_in_uncast_before`, ADR 0870)

`phase_power_in_uncast_before` is `true`, on an entry with `phase_power` `[power, before, after]` whose before phase does
not cast the trigger (`cast_in_before` false or `trigger_only_after`). `phase_power` alone sets the power only right
before each phase's cast, so an uncast before phase reads the fixture's starting power. With the option, the uncast
before phase also sets `power` to `before` at its start, ahead of its read. The after phase is unchanged.

Named points: `check`, `phase_steps`, `fixtures`, `model`.

Witch Hunter: Heartseeking Bolt 807284 `rage` (Rage after one bolt, claim 383.0).
