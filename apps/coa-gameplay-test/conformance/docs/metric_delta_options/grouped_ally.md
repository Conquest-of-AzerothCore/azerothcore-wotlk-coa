# Grouped ally (`metric_delta` `grouped_ally`, ADR 1174, provisional)

`grouped_ally` is `{"dy": yd, "grouped": bool}` (`dy` nonzero, at most 20 either way). The scenario adds a second
player `ally` of the caster's race and class, moves it `dy` yd along y from the caster after the base steps and,
when `grouped`, groups it with the caster. The ally may be the measured unit, the user of
[`use_gameobject_after`](use_gameobject_after.md) (`user: ally`) or the target of
[`dummy_casts_at_caster`](dummy_casts_at_caster.md) (`target: ally`). It is not a cast target of the entry and not
an enemy player scenario. Absent, the scenario is unchanged.

Named point: `fixtures`.

Witch Doctor: Mojo Cauldron 807908 `ally_mojo` and `stranger_mojo` (a grouped ally uses the caster's Cauldron, an
ungrouped one is refused); War Golem 800330 `golem_redirect` (the dummy's casts at a grouped ally go to the golem).
