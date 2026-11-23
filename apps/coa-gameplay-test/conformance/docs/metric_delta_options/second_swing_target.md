# Second swing target (`metric_delta` `second_swing_target`, ADR 1219, provisional)

`second_swing_target` (an area dummy id, `area1` to `area9`) makes each attack phase of an `attack_swings` entry go on
to a second target: after the swings at the dummy and the `stop_attack`, the caster attacks that area dummy for the
same wait and stops again, in both phases. The area dummy comes from `area_dummies` and must stand at the dummy's
distance (the melee placement, so facing and reach are the dummy's). Refused without `attack_swings`, with
`gate_cast`, or without that area dummy. The scenario timeout is recomputed with the added waits. Absent, each phase
attacks the dummy only.

Named point: `fixtures` (the second attack block of each phase).

Sun Cleric: Valiance 680643 (ledger row 195, claim 2) "your first auto attack on a target hits twice":
`second_target` counts the caster's casts of 681472 (0 before, 2 after: one per target), `second_marker` reads the
caster's 681531 marker on `area1` (0 before, 1 after).
