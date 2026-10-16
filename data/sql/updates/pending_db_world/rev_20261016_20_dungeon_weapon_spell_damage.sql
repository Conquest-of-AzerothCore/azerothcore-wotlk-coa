-- Shadow Cleave (Lord Alexei Barov) and Throw Food (Cookie) deal a share of the caster's weapon damage, which already
-- carries the Heroic/Mythic DamageModifier calibrated to Ascension's combat logs (rev_20261005_20). Their
-- coa_dungeon_spell_damage multipliers (x8.0 and x2.75) were tuned against the older, lower DamageModifier and now
-- scale that damage a second time (Mythic Shadow Cleave about 8,400 instead of about 1,050 before M+ scaling).
DELETE FROM `coa_dungeon_spell_damage` WHERE `spell_id` IN (2100356, 2102589);
