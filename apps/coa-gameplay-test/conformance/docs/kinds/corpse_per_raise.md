# Corpses per raise (`behaviour_metric_delta`, `kind: "corpse_per_raise"`, ADR 0595)

`spell` is cast at the dummy before it is learned (control: refused) and after it; every `poll_ms` the game time, the
caster's `spell_cast_count` of `raise_spell` (triggered casts included) and the dead `corpse_entry` creatures in its
phase (`nearby_creature_count` with `dead`) are read. The corpses that appear (the sum of the count's rises) must equal the
raises cast up to `death_ms` before the window ends and at most all raises; fewer than 2 settled raises is unmeasured,
a control raise or corpse alerts.
