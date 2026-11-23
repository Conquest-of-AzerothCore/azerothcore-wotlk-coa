# Before aura absent (`metric_delta` `before_aura_absent`, ADR 0653)

`before_aura_absent` is `{"aura": id, "entry": id, "source": text}`. Right before the before reading, the scenario
reads `owned_creature_aura_max_duration_ms` of `aura` on the caster's owned creature `entry` (0 when absent). A run in
which the creature holds the aura, or the read is missing, is `unmeasured`: the control is not the plain one. With the
aura absent the verdict is the plain `metric_delta` verdict. `source` names where the aura comes from.

Named point: `verdict(verdict, run, value)`, as `strike_landed`; `fixtures` adds the read.

Necromancer: Ghoul Mastery 503740 `snare_control` (Dazed 1604 from the defensive striker's melee from behind, read
0.57143 before the learn in the cycle 14 pair; claim 389.0).
