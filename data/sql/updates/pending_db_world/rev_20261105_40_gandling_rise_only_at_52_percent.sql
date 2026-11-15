-- Darkmaster Gandling casts Rise! only once, at 52% health (2100397): a 10 s aura that summons a Risen Student
-- (2100398) every 1.5 s and halves his damage taken. The kit row that also cast 2100398 every 3-3.5 s from the start
-- of the fight does not exist on any difficulty on Ascension (Mythic 13 Scholomance footage).
DELETE FROM `coa_dungeon_boss_kit` WHERE `entry` = 1853 AND `id` = 1 AND `spell` = 2100398;
