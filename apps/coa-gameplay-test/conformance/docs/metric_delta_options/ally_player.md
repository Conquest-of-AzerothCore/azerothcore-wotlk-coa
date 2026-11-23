# Ally player (`metric_delta` `ally_player`, ADR 1162)

`ally_player` is `{"class": id, "power": index}`. It adds a player `ally` of that class (the caster's race and level,
regeneration off), grouped with the caster after the settle steps, and sets the ally's power of that index to 0 at the
start of each phase (the named point `phase_steps`). The entry's `target` and `measure_actor` must be `ally`; it takes
a plain cast trigger, without an enemy player, attack swings or setup casts. Absent, the scenario is unchanged.

Use it for a claim about a resource the caster's own class does not have (Rage, Energy, Focus): an energize on a unit
whose maximum of that power is 0 does nothing, so only an ally of a class that owns the power can show it. Pair it
with [`ratio_to_metric`](ratio_to_metric.md) on `max_power` of the same power to read the share of the maximum.

Named points: `check`, `phase_steps`, `fixtures`.

Witch Doctor: Rage Brew 503750 `brew_rage` (a Warrior, Rage), `brew_energy` (a Rogue, Energy) and `brew_focus` (a
Ranger, Focus): 0 before the cast and half of the maximum after it, claim 79.0.
