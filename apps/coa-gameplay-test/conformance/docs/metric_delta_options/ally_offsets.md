# Ally offsets (`metric_delta` `ally_offsets`, ADR 1196)

`ally_offsets` is `{"<ally id>": yards}`: each named grouped ally of the entry's [`ally_arm`](ally_arm.md) is moved
that far along x from the shared spawn, right after the `group` steps and before either phase, in harness `relocate`
steps of at most 20 yd (the `run.py` bound) with dz 0. The caster stays at the spawn. Each distance is above 0 and at
most 100 yd; an id that is not a grouped ally of the entry is refused.

It adds no check and no reading. State the distances with `ally_arm` arms reading `distance_2d` (`fields.target`
`caster`) on the moved allies, and the reach with heal or aura arms on each side of the edge. The 3D distance equals the
2D one only while the ground under the units keeps the spawn's height (dz 0); the entry states that premise.

Sun Cleric: Lights of Absolution 807343 `ally_radius` (807524, 40 yd): ally at 39 yd is healed, ally2 at 41 yd is not.
