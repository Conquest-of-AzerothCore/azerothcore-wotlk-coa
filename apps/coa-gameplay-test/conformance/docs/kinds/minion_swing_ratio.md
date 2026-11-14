# Minion swing ratio (`behaviour_hit_ratio`, `kind: "minion_swing_ratio"`, ADR 0541)

A minion's command strike stated as "Weapon Damage" is read against the same minion's own swing. A real
`raise_spell` raises creature `entry` at the caster; one `command_spell` at the dummy (power set to `command_power`)
starts its attack, then `trials` more follow, `wait_ms` apart. After the first and each later Command the scenario
reads the non-critical, unblocked `strike_spell` hits of that creature on the dummy (`spell_damage_total` and
`spell_damage_count` with `caster_entry`) and its plain melee swings (`pet_melee_plain_damage` and
`pet_melee_plain_count`, no crit and no glancing). The hit ratio judge takes the swings as the control arm and the
strike as the treatment: the per-hit mean of the strike over the per-swing mean must lie within 5% of the stated
ratio `expected` (`ratio_band`, the G-19 band of a ratio), with the 99% interval rules of the hit ratio judge. The
creature's minimum weapon damage (`owned_creature_weapon_damage_min`) is recorded once and not judged. Raise:
`strike_flat` takes that flat amount off every strike hit before the ratio (ADR 0547). Greater Skeletal Warrior 504901
judges Command: Skeletal Warriors 570042 at 2.0 after its flat Effect[1] part of 1 (fix FN-c1t-1, controller cycle 2). `player_spell_power` gives the
caster the harness spell-power fixture; weapon_ratio_sp holds 1000, a flat part of 137.5.
`learn` lists spells learned before the raise (a Life Force gate such as Summoning Adept 92123). `strike_flat_armor:
true` reads `armor_reduced_damage` of `strike_spell` on the dummy once (per 1000, the caster as the attacker, at the
minion's level) and the judge scales `strike_flat` by it before taking it off a Physical strike, whose flat part the
dummy's armor reduces with the weapon part (ADR 0631). Raise: Decaying Colossus 500989 judges Bone Smash 505229 at 1.0
after its armor-scaled flat 100.
