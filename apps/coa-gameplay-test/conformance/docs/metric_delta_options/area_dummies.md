# Area dummies (`metric_delta` `area_dummies`, ADR 0995)

`area_dummies` (a list of 1 to 9 distances in yd) adds creatures `area1`, `area2`, ... beside the entry's dummy:
copies of the dummy fixture, each at its distance from the caster. Setup casts keep the dummy as their target, so an
area spell can strike a marked dummy and unmarked ones in the same cast; the entry reads one of them through
`fields.target` (`dummy`, `area1`, ...). An entry needs the dummy in its scenario.

Named point: `fixtures` (the extra creatures).

Witch Hunter: Slayer's Mark 804068 (claim 351.1, Witch Hunter ADR 0024): Witchblight 681220 strikes three dummies;
only the marked one gains the attacker bonus (`ap_melee_area`, `ap_melee_area_unmarked`, `ap_melee_area_control`).
