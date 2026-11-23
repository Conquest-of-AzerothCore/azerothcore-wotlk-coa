# Extra corpses (`metric_delta` `extra_corpses`, ADR 0620)

`extra_corpses` (a list of `{"entry", "health", "distance"}`) adds more corpse fixtures beside the
[`corpse`](corpse.md) one: creatures `corpse2`, `corpse3`, ... at the class level, with that health, `distance` yd
from the caster. In the treatment phase only, right after the entry's single setup cast kills `corpse`, the same setup
spell is cast at each extra corpse (its cooldown reset first, `setup_wait_ms` after each). The control phase has no
corpse. An entry needs the `corpse` fixture and exactly one setup cast.

Named points: `setup_cast_steps` (the extra kills after setup cast 0) and `fixtures` (the extra creatures).

Necromancer: Corpse Explosion 533239 (claim 325.0): two Humanoid corpses strike the dummy twice, against one corpse
once (the `fewer_corpses` control).
