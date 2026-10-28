-- Guardians have no Shoot (5019), so the Wands proficiency (5009) only let them equip a wand they cannot use (#8547).
DELETE FROM `playercreateinfo_spell_custom` WHERE `racemask` = 0 AND `classmask` = 131072 AND `Spell` = 5009;
