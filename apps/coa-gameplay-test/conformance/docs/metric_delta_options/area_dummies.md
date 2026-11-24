# Area dummies (`metric_delta` `area_dummies`, ADR 0995)

`area_dummies` (a list of 1 to 11 distances in yd, ADR 1265: the dummy and 11 fill the 12 creatures `run.py` admits)
adds creatures `area1`, `area2`, ... beside the entry's dummy: copies of the dummy fixture, each at its distance from
the caster. Setup casts keep the dummy as their target, so an area spell can strike a marked dummy and unmarked ones
in the same cast; the entry reads one of them through
`fields.target` (`dummy`, `area1`, ...). An entry needs the dummy in its scenario.

Named point: `fixtures` (the extra creatures).

Witch Hunter: Slayer's Mark 804068 (claim 351.1, Witch Hunter ADR 0024): Witchblight 681220 strikes three dummies;
only the marked one gains the attacker bonus (`ap_melee_area`, `ap_melee_area_unmarked`, `ap_melee_area_control`).

## Cone form (ADR 1224)

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

## Edge form (ADR 1224 addendum)

`area_dummies` may instead be `{"edge": {"radius": yd, "source": text, "reach": yd, "reach_source": text, "leeway":
bool, optional "margin_pct" (default 10)}}`. The edge is the DBC radius (`source`) plus the dummy's combat reach
(`reach`, cited from the data rows in `reach_source`) that a player caster's area search adds to a non-player unit
target (Spell.cpp:9437-9442), plus, with `leeway`, the player caster's area leeway 2.66 yd (Spell.cpp:1388-1394,
Object.cpp:1787-1808, ADR 1190; the hit spell needs TargetA/B 15, 20 or 56). `area1` stands `margin_pct` percent
inside the edge and `area2` as far beyond it, on the dummy's line. Before the last trigger cast the option reads the
positions of the caster, `area1` and `area2`, their combat reaches and, with `leeway`, the caster's run speed rate;
after the after reading it reads the hit spell's `spell_damage_count` on `area1` and `area2`. The verdict recomputes
the 3D distances and the edge from the reads, which only check the stated inputs: a reach more than 0.01 yd off the
stated one, a recomputed leeway that differs, a distance more than 0.25 yd off its plan, or a layout that does not
bracket the edge voids the trial (`unmeasured`). Otherwise `area1` unstruck or `area2` struck alerts. The caster's own
combat reach is recorded, never judged. It needs `fields.spell` and a `spell_damage_count` or `spell_damage_total`
metric, works with `area_sum`, and refuses `relocate_before_trigger`, `relocate_during_wait` and
`moving_before_trigger`.

Sun Cleric: Hope 680637 `split_radius` (570187 radius 8 yd, dummy entry 36 reach 1.275 yd, leeway: edge 11.935 yd,
mentor D-259).
