# Follow bearing (`behaviour_metric_delta`, `kind: "follow_bearing"`, ADR 0605)

A minion that follows at a stated side of its owner ("flies behind the Necromancer"). The caster faces a friendly
stationary dummy `front_yd` out (faction 35, so no minion engages it). The control (`control_raise`, creature
`control_entry`, a stock follow angle) is raised alone and read after `settle_ms`; then the follower
(`follower_raise`, creature `follower_entry`) is raised and read the same way. Each read is the creature's exact 2D
distance to the caster and to the dummy (`owned_creature_distance_2d`), with the caster's distance to the dummy; the
bearing from the caster's facing follows from the law of cosines. The follower must stand at 135 degrees or more and
the control under 135; a control behind the caster, or a creature closer than 0.5 yd, is unmeasured.

Necromancer: Animate: Frost Wyrm 805428, Wyrm 50177 against a Raise: Ghoul 50073 (claim 269.1).
