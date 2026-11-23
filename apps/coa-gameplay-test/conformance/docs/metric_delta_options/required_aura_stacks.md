# Required aura stacks (`metric_delta` `required_aura_stacks`, ADR 1138)

`required_aura_stacks` is `{"spell": id, "stacks": n}`, the CasterAuraSpell of the trigger or of a setup cast. The
precondition fixture the scenario sets before that cast (`set_aura`, one stack by default) is set to `n` stacks, for a
cast whose effect scales with the stacks it consumes. Absent, the scenario is unchanged.

Named point: `fixtures`.

Witch Doctor: Frenzied Spirits 560748 `heal_three` (three Spirits 561136 consumed) and `heal_one` (one).
