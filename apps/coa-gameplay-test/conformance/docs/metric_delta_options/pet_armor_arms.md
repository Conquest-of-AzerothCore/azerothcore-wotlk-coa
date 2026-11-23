# Pet armor arms (`metric_delta` `pet_armor_arms`, ADR draft nf-e)

`pet_armor_arms` (`{"summon": S, "entry": E, "bare_aura": B, "armor_aura": R, "trials": T, "window_ms": W}`)
replaces the entry's phases. `S` summons the current pet, read back as `pet_entry` `E`; its plain melee swings are
read by its pet GUID (`pet_melee_plain_damage` and `pet_melee_plain_count` with no `entry`: an entry match never
selects a Pet). Two dummies of one fixture: `dummy` holds `R` (an armor raise) and `bare_dummy` holds `B` (an armor
removal); both auras are removed and set again before every window, because `set_aura` on a held aura keeps its
running duration, and both dummies' armor is read at every window end. Four arms of `T` windows of `W` ms, the pet
attacking one dummy at a time: without the trigger on `dummy` then `bare_dummy`, then with the trigger, cast at the
caster before every window (`cast_power` sets the power first), on `dummy` then `bare_dummy`. `armor_reduced_damage`
of the pet (`pet: true`, Auto Attack 6603, per 1000) is read on both dummies before and after the first trigger cast:
the READBACK data arm.

Verdict (its own): with the trigger, the per-hit plain damage on `dummy` over `bare_dummy` must be 1.0; without it,
the same ratio must equal the read `armor_reduced_damage` of the pet against `dummy` per 1000; both within 5% of the
ratio with the 99% interval rules of the hit ratio judge (`alert` when either interval leaves its band, not judged
when a half-width exceeds half the band). `unmeasured` when a read is missing, the pet is not `E`, `bare_dummy` is not
at 0 armor or unreduced, `dummy` has no armor, an armor read changes during the arms, or the trigger aura is not on
the pet at the end of a with-arm. The entry reads `pet_melee_plain_damage`, an event read (EVENT row in this module).

Witch Hunter: Decimate 804194 `hound_ignore_armor` (Shadowhound 50124 by Houndmaster's Whistle 801343, Harden Skin
22693 +10000 armor, Dematerialize Armor 40935 -100%).
