# Corpse fixture (`metric_delta` `corpse`, ADR 0493)

`corpse` (`{"entry", "health", "distance"}`) adds a creature `corpse` of that entry, at the class level, with that
health, `distance` yd from the caster. A `setup_only_after` entry kills it with a real cast (`setup_target:
"corpse"`, for example Void Zone 92559 for 1000 Physical damage) in the treatment phase only, so the control phase has
no corpse. Corpse Explosion 533239: a Humanoid corpse explodes on the dummy near it, a Mechanical (480) or an Elemental
(2022) corpse does not.
