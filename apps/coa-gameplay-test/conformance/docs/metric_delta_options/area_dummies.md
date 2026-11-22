# Area dummies (`metric_delta` `area_dummies`, ADR 0995)

`area_dummies` (a list of 1 to 9 distances in yd) adds creatures `area1`, `area2`, ... beside the entry's dummy:
copies of the dummy fixture, each at its distance from the caster. Setup casts keep the dummy as their target, so an
area spell can strike a marked dummy and unmarked ones in the same cast; the entry reads one of them through
`fields.target` (`dummy`, `area1`, ...). An entry needs the dummy in its scenario.

Named point: `fixtures` (the extra creatures).

Witch Hunter: Slayer's Mark 804068 (claim 351.1, Witch Hunter ADR 0024): Witchblight 681220 strikes three dummies;
only the marked one gains the attacker bonus (`ap_melee_area`, `ap_melee_area_unmarked`, `ap_melee_area_control`).

## Cone form (ADR 1055)

`area_dummies` may instead be `{"cone": {"angle": degrees, "radius": yd, "source": text, optional "offset" (yd, default
6), "margin_pct" (default 10), "behind" (degrees, default 135)}}`. `source` cites the data or the code line that sets the
angle, never a reading. The dummy (the primary, struck), `area1` (just outside the edge) and `area2` (behind the
caster) are placed on the line, and the caster is moved off it by a `relocate` step so they stand at bearings
`angle/2 less margin_pct`, `angle/2 plus margin_pct` and `behind` from its facing. The entry judges the dummy's
`spell_damage_count` of the hit spell (expected 1); the option reads the positions and the caster's orientation,
recomputes every bearing, voids the trial (`unmeasured`) when one is more than 1 degree off its plan, a height is more
than 1 yd off the caster's or a distance lies outside 4 yd and `radius`, and alerts when `area1` or `area2` is struck.
It refuses a setup cast, `area_sum`, `relocate_before_trigger` and a trigger cast in the before phase.

Sun Cleric: Shield Radiance 504580 `cone_edge` (90 degrees from `spell_cone` 800654, Spell.cpp:1277-1279).
