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

`area_dummies` may instead be `{"cone": {"angle": degrees, "radius": yd, "source": text, optional "offset" (yd, 0.5 to
12, default 6), "margin_pct" (default 10), "behind" (degrees, default 135)}}`. `source` cites the data or the code line
that sets the angle, never a reading. The dummy (the primary, struck), `area1` (just outside the edge) and `area2`
(behind the caster) are placed on the line, and the caster is moved off it by a `relocate` step so they stand at
bearings `angle/2 less margin_pct`, `angle/2 plus margin_pct` and `behind` from its facing. The entry judges the
dummy's `spell_damage_count` of the hit spell (expected 1); the option reads the positions and the caster's
orientation, recomputes every bearing, voids the trial (`unmeasured`) when one is more than 1 degree off its plan, a
height is more than 1 yd off the caster's or a distance lies outside 4 yd and `radius`, and alerts when `area1` or
`area2` is struck. It refuses `area_sum`, `relocate_before_trigger`, a trigger cast in the before phase, and any
`setup_casts` that repeat the trigger or hit spell or run in `setup_in_before`/`setup_only_after`; treatment-only
`setup_casts` targeting the dummy run before the cone relocation (ADR 1293).

Sun Cleric: Shield Radiance 504580 `cone_edge` (90 degrees from `spell_cone` 800654, Spell.cpp:1277-1279).
Cultist: Eldritch Force 681474 `cone_edge` (24 degrees, 8 yd, offset 1.0 yd, behind 166 degrees, with 5 Ancient Curse
500712 crit setup casts before relocation, ADR 1293).

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

## Placed form (ADR 1307, provisional)

`area_dummies` may instead be `{"placed": [{"dx": yd, "dy": yd, "before_expected": num, "expected": num, optional
"tolerance": num}, ...], optional "casts_before": [spell, ...]}` with 1 to 11 placements, each a non-zero `(dx, dy)`
offset from the caster (planar distance at most 100 yd, distinct from one another and from the primary dummy), and at
least one placement expecting a change (`expected != before_expected`). Each extra dummy (`area1`, `area2`, ...) is
spawned with `dx` and `dy` instead of `distance`. When `casts_before` is named, every placed dummy casts those spells
before the `before` reading (or before the `before` trigger cast when `cast_in_before` is true) and again before the
treatment trigger cast, each followed by the standard target-cast settle wait.

Before the treatment trigger cast, `position_x`, `position_y` and `position_z` are read on the caster, the primary
dummy and every placed dummy; after each phase's primary reading, the entry's metric is read on every placed dummy.
The judge voids the trial (`unmeasured`) if any dummy's read planar position differs from its planned `(dx, dy)` by
more than 0.25 yd or its height differs from the caster's by more than 1.0 yd, and alerts if any placed dummy's
`before` or `after` reading misses its stated expectation and tolerance. When the entry reads `casting`, the option
stamps `evidence_metric: "area_casting"` (a `state` metric whose `STATE_PROMISES` match `"all enemies"`, `"around
you"`, `"nearby enemies"`, `"interrupt..."` and `"cast..."`). It refuses `area_sum`, `attack_swings`, relocation
options (`relocate_before_trigger`, `relocate_during_wait`, `moving_before_trigger`), non-target metrics and a
conflicting `evidence_metric`.

Cultist: Crushing Dissonance 804056 `interrupt_around` (claim 375.2 `"of all enemies around you"`, 4 dummies placed at
`(-5, 0)`, `(0, 5)`, `(0, -10.5)` inside the 11.935 yd edge and `(14, 0)` outside, all casting Evocation 12051).
